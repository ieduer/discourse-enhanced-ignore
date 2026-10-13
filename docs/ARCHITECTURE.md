# Architecture and research notes

Research date: **2026-10-13**. Discourse inspected: `main` at commit
[`709839f7d24d89b4f8f1e09f46efff3357fa3fe5`](https://github.com/discourse/discourse/commit/709839f7d24d89b4f8f1e09f46efff3357fa3fe5)
(`2026.10.0-latest`). Paths below are relative to that commit. Line numbers
drift; file names are the stable reference.

## 1. What Discourse already does

| Area | Native behaviour | Source |
| --- | --- | --- |
| Who can ignore | Staff, or members of `ignore_allowed_groups`; never yourself or staff. | `lib/guardian.rb` (`can_ignore_user?`, `can_ignore_users?`) |
| Storage | `ignored_users` rows with a mandatory `expiring_at`. Choosing Ignore removes a Mute on the same user and vice versa. | `app/models/ignored_user.rb`, `UsersController#notification_level` |
| Expiry | A daily job deletes expired rows. Nothing is pushed to open browsers. | `app/jobs/scheduled/purge_expired_ignored_users.rb` |
| What the browser knows | `currentUser.ignored_users`: an array of **usernames** (no ids), sent with the page bootstrap. Updated in place when the member ignores or un-ignores someone from a profile or user card. | `app/serializers/current_user_serializer.rb`, `frontend/discourse/app/models/user.js` (`updateNotificationLevel`) |
| Replies in a topic | Removed **on the server** from the topic view, except post #1 and posts by staff. | `lib/topic_view.rb` (`setup_filtered_posts`) |
| Live new replies | Dropped by the client when the author is in `ignored_users`. | `frontend/discourse/app/controllers/topic.js`, `models/post-stream.js` |
| Post #1 and embedded posts | Body replaced by the text "Ignored content"; avatar and names still shown. | `frontend/discourse/app/components/post/cooked-html.gjs` |
| Quotes **with** a post reference | Body left empty and the expand button removed when `data-username` is exactly (case-sensitively) in `ignored_users`; the title with avatar and name is still shown. | `frontend/discourse/app/components/post/quoted-content.gjs`, `lib/post-cooked-html-decorators/quote-controls.gjs` |
| Quotes **without** a post reference (`[quote="name"]`) | Not handled: fully visible. | same decorator returns early without `data-post` |
| Topic lists | Not filtered (only the digest email query is). | `lib/topic_query.rb`, `app/models/topic.rb` (`for_digest`) |
| Notifications, likes list | Not generated / filtered on the server. | `app/services/post_alerter.rb`, `PostActionUsersController` |
| Nested replies view | Own placeholder with a reveal button. | `frontend/discourse/app/components/nested/post.gjs` |

So the remaining exposure this component addresses is: quote titles, quotes
without a post reference, case-different attributions, the identity shown on
post #1 and embedded posts, reply-to headers, posts already on screen when
someone is ignored, expanded quotes whose attribution does not match the real
author, topic lists, search results, and avatars.

## 2. Theme component or plugin?

A **theme component** is sufficient. Everything above is a display decision
that can be taken in the browser from data Discourse already sends, and every
surface has a supported frontend hook or a stable attribute. A plugin would
only add: account-level storage of the on/off switch, and server-side
filtering of topic lists (so counts and pagination shrink too). Neither is
essential, and a plugin cannot be installed on hosted plans or without a
rebuild, so the trade was not worth it.

Consequence: the on/off switch is stored in the browser (see section 4), and
hidden topics still count towards list pagination and the "New"/"Unread"
counters.

## 3. Extension points used

All from the current `frontend/discourse/app/lib/plugin-api.gjs`.

| Surface | Hook | Why this one |
| --- | --- | --- |
| Posts in the stream | `registerValueTransformer("post-class")` | Receives the post model; reactive; adds a class only. |
| Placeholder for a hidden post | `renderBeforeWrapperOutlet("post-content-cooked-html")` | Real, localised, accessible text instead of CSS-generated content. |
| Reply-to header | same `post-class` transformer, from `post.reply_to_user` | No DOM lookups. |
| Quotes, embedded posts, expanded quotes | `decorateCookedElement(..., { onlyStream: true })` + `helper.renderGlimmer` | The supported cooked-content lifecycle: runs on a detached copy on first render, re-render, edit and nested rendering; cleaned up by Discourse. `onlyStream` limits it to content rendered through the post component, so the composer preview and the review queue are not touched. |
| Topic lists | `registerValueTransformer("topic-list-item-class")`, `("latest-topic-list-item-class")` | Receives the topic model; covers every list built on the shared item components. |
| Search results, profile activity, avatars | A generated `<style>` element keyed on `data-user-card` | These surfaces have no class transformer; the attribute is long-standing markup. Pure CSS means no scanning and no flash. |
| Preference control | `renderInOutlet("user-custom-controls")` | Sits on Preferences > Users, directly under the native Ignored list. |
| Style host | `renderInOutlet("above-site-header")` | Always rendered; gives the generated styles autotracked updates and teardown. |

Not used, on purpose: widget APIs, `modifyClass`, `MutationObserver`, timers,
document-wide queries, per-post network requests.

### Data flow

```
currentUser.ignored_users (native, autotracked)
        │
        ▼
EnhancedIgnoreState ── enabled? (localStorage, per site + user id)
        │  ignoredSet = normalised usernames (derived, never stored)
        ├──► value transformers ──► CSS classes on posts / topic rows
        ├──► cooked decorator ───► guard component per attributed quote
        └──► generated <style> ──► [data-user-card="…" i] rules
```

Every consumer reads the same derived set, so ignoring or un-ignoring someone
from a user card updates posts, quotes, lists and the stylesheet in the same
render, without a reload.

## 4. Decisions

**Matching.** Only usernames are available, so matching is by whole username
after NFC normalisation and lower-casing, mirroring `User.normalize_username`.
No display names, no substrings, no body text. A renamed user is matched under
the new name in the list; old quotes that still carry the previous username in
their markup are not matched.

**Quotes.** The unit that is hidden is the `aside.quote` element whose
`data-username` matches. Hiding it hides everything nested inside it (one
placeholder), while an ignored quote nested inside someone else's quote hides
only itself. Quotes without `data-username`, Markdown blockquotes and prose
are never touched. Attribution is author-supplied markup, so this is a
convenience, not a guarantee.

**Replies.** A post that replies to an ignored user is kept. Only the reply-to
header (avatar + name of the ignored user) is hidden. There is no "hide
everything downstream" mode: it cannot be done reliably from the client.

**No "show once".** Discourse itself strips the body of ignored quotes and
first posts before themes run, so a reveal button could only work for some
cases, or would need one request per post. The placeholder is therefore plain
text; to read the content, switch the preference off or un-ignore the user.

**Persistence.** Theme components cannot add a user option. The only
account-level routes (an admin-created user field exposed through
`public_user_custom_fields`) would publish who enabled the feature, so the
switch is stored in `localStorage` under
`discourse-enhanced-ignore:v1:<site base path>:<user id>`. It is per browser,
per site and per account, and is not synced.

**Timing.** Transformer classes and the generated stylesheet apply in the same
render as the content, and quote classes are set on the detached element
before it is inserted. The stylesheet is created by the first application
render, so there is no hook earlier than Discourse's own boot. No zero-flash
claim is made.

**Failure mode.** Each registration is wrapped; a hook missing on another
Discourse version logs one `[enhanced-ignore]` console warning and disables
only that surface.

## 5. Coverage matrix

See the README, which is the maintained copy.
