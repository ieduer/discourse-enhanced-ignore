# Enhanced Ignore for Discourse

A Discourse **theme component** that lets each member extend their own
**Ignore** list to the places where an ignored user's content still shows up:
quotes inside other people's posts, reply-to headers, expanded replies, topic
lists, search results and avatars.

It is a personal display preference. It uses the member's native Ignored list,
is off until the member switches it on, and never changes what anyone else
sees.

> **What it is not.** Hiding happens in the browser. The content is still on
> the server and still present in API responses, network traffic, page source,
> email digests, push notifications, RSS feeds, data exports and other clients
> or apps. This is not mutual blocking, not moderation, and not a guarantee
> that you will never see a person. See [Privacy and limits](#privacy-and-limits).

> **Status: 0.1.0, not yet verified on a running forum.** The code passes
> linting, type checks, configuration validation and unit tests, and was
> written against the current Discourse source, but it has not been installed
> on a live Discourse instance yet. See [Verification status](#verification-status)
> and the [manual test checklist](docs/MANUAL_TEST_CHECKLIST.md) before relying on it.

## What it looks like

No screenshots are published yet: they will be added from a real installation
rather than mocked up. The intended result, using synthetic accounts where
`viewer` ignores `quinn` (and does not ignore `quinn2` or `alice`):

A post by `alice` written as

```
Thanks both. I will try an early cherry type first.

[quote="quinn, post:2, topic:7"]
Only heirloom varieties are worth growing.
[/quote]

I would rather get a harvest at all, so that can wait.

[quote="quinn2, post:3, topic:7"]
Early cherry types ripen in about eight weeks here.
[/quote]
```

| | What `viewer` sees |
| --- | --- |
| Native Discourse | alice's text, then a quote box titled with **quinn's avatar and name** and an empty body, then alice's text, then quinn2's quote. |
| Enhanced Ignore on | alice's text, then one muted line *"Quote hidden (ignored user)"*, then alice's text, then quinn2's quote unchanged. |

In the topic list, a topic started by `quinn` is listed natively and is not
listed with Enhanced Ignore on; a topic by `alice` in which `quinn` replied
stays, without quinn's avatar in the posters column. Opening a topic started
by `quinn` natively shows quinn's avatar and name above "Ignored content";
with Enhanced Ignore on it shows *"Post hidden (ignored user)"* without the
avatar or name, and everyone else's replies as usual.

## Install (administrators)

1. Open **Admin > Appearance > Themes and components > Components** and choose **Install**.
2. Choose **From a git repository** and enter
   `https://github.com/ieduer/discourse-enhanced-ignore`
3. After it installs, open the component and, under **Include component on
   these themes**, add every theme your members can select. A component that
   is not attached to a theme does nothing.
4. Optional: review the one setting below.

Nothing changes for members until they opt in (or you turn on
`enabled_by_default`).

Members must also be allowed to use Discourse's Ignore feature in the first
place: that is the core site setting **`ignore allowed groups`** (staff can
always ignore). This component does not change who may ignore whom.

### Setting

| Setting | Default | Effect |
| --- | --- | --- |
| `enabled_by_default` | off | When on, members who have not made their own choice get Enhanced Ignore switched on. Any member can still switch it off. Leave it off for a strictly opt-in feature. |

## Use (members)

**Switch it on or off**

1. Click your avatar (top right) > the person icon > **Preferences**.
2. Open the **Users** tab (`/my/preferences/users`).
3. Under **Enhanced ignore**, tick or untick **"Also hide quotes, reply
   previews and topics from users I ignore"**.

The change is saved immediately (there is no Save button to press) and applies
from the next page you open. The line under the checkbox tells you whether it
is on and for how many ignored users.

**Manage who is ignored** — this is Discourse's own feature and works as before:

- Same page, **Users > Ignored**: add a username and choose a duration, or
  remove one.
- Or open someone's profile or user card, use the notification-level dropdown
  (**Normal / Muted / Ignored**), choose **Ignored** and a duration.

Ignores always have an end date; Discourse removes them when they expire.
Ignore and Mute are separate lists. This component only reads **Ignored**.

### Where the choice is stored

A theme component cannot add an account setting, so the on/off choice is kept
in **this browser's local storage**, separately for each site and each
account:

- It is **not synced**. Switch it on again on your phone, another browser, or
  after clearing site data. Private windows forget it when closed.
- Two people using the same browser profile with different accounts do not
  affect each other.
- Your Ignored list itself is stored by Discourse in your account, as always.
  The component keeps no copy of it and stores no usernames or post content.

## Coverage

Legend: **Implemented** = code is in place; behaviour on a live forum is
awaiting verification (see [Verification status](#verification-status)) ·
**Partial** = implemented with a stated gap · **Native** = Discourse already
handles it, unchanged · **No** = deliberately not handled · **Unverified** =
depends on other code, no claim.

### Topic pages

| Surface | Status | Notes |
| --- | --- | --- |
| Replies by an ignored user | Native | Discourse removes them on the server. |
| First post of a topic by an ignored user | Implemented | Avatar, names and body are hidden behind "Post hidden (ignored user)". Natively only the body is replaced. |
| Post already on screen when you ignore its author | Implemented | Collapses immediately; after a reload Discourse removes it. |
| Quote attributed to an ignored user, with a post link (`[quote="name, post:2, topic:5"]`) | Implemented | Whole quote replaced by "Quote hidden (ignored user)". Natively the avatar and name stay visible. |
| Quote attributed by name only (`[quote="name"]`) | Implemented | Not handled natively at all. |
| Attribution in different letter case | Implemented | |
| Several quotes in one post | Implemented | Each handled separately; the author's own text is kept. |
| Nested quotes | Implemented | An ignored outer quote hides its whole subtree behind one placeholder. An ignored inner quote hides only itself. |
| Expanding a quote whose attribution names someone else but which links to an ignored user's post | Implemented | The expanded body is hidden. The short excerpt typed by the quoting author stays: see limits. |
| Quote with no attribution, Markdown `>` blockquote, unclosed/malformed quote | No | No reliable author. Left visible. |
| Mentions (`@name`) and the name in ordinary prose | No | That is the other author's writing. |
| Reply-to header ("in reply to" tab) naming an ignored user | Implemented | The header is hidden; the reply itself is kept. |
| Replies panel under a post ("N Replies") | Implemented | Entries by ignored users are omitted. The number on the button is not changed. |
| Posts loaded by scrolling, live updates, edits | Implemented | |
| Avatars in the topic map / participants | Partial | Hidden by markup-based rules. |
| Screen-reader post heading of a hidden first post | Partial | Discourse's visually hidden heading for the post still contains the username. |
| Nested replies view (`nested_replies_enabled`) | Native | Has its own placeholder and reveal button; not extended. |
| Post history, raw post, print view, embedded comments (`/embed`) | No | Outside the post stream or outside the app. |

### Lists and other pages

| Surface | Status | Notes |
| --- | --- | --- |
| Latest, New, Unread | Implemented | Topics *started* by an ignored user are hidden. Topics they only replied in stay. |
| Category and tag pages | Implemented | |
| Categories page with "Latest" column | Implemented | |
| Suggested / related topics under a topic | Implemented | |
| Mobile topic list | Implemented | |
| Topics loaded by infinite scrolling | Implemented | |
| Ignored user's avatar in a list's posters column | Implemented | |
| Full-page search results (`/search`) | Implemented | Results whose post author is ignored. |
| Header quick-search dropdown | No | Results carry no author. |
| Profile activity and notification streams | Partial | Entries whose avatar belongs to an ignored user are hidden by markup-based rules. On the ignored user's own profile this hides their activity entries. |
| Category boxes with featured topics, bookmarks list, topic lists from other plugins or themes | Unverified | Hidden only if they use the standard topic-list item. |
| Counters ("New (3)", unread badges), page size | No | Hidden topics still count. Nothing is ever marked read for you. |
| Notifications menu | Native | Discourse does not create notifications from ignored users. Older ones are left as they are. |
| "Who liked" lists | Native | Filtered by Discourse. |
| Chat | No | Separate rendering and its own rules. |
| Personal messages | Partial | Message topics render like topics, so quotes and posts are treated the same; the message list is not filtered. Discourse already restricts PMs from ignored users. |
| Review queue, admin pages, composer preview | No | Left untouched on purpose so moderation and writing are never affected. |
| Other plugins' interfaces | Unverified | |
| Email, push, RSS, API, exports | No | Not reachable from a theme component. |

## Privacy and limits

- **Not a security or safety boundary.** Everything hidden is still delivered
  to your browser.
- **Quote attribution is typed by the quoting author** and can be wrong,
  edited or forged. A quote attributed to someone else is not detected, and a
  quote falsely attributed to an ignored user is hidden.
- **Copied text, paraphrases, screenshots, image text and external embeds**
  are never detected. There is no text matching, OCR or AI.
- **Renames.** After a rename, old quotes still carry the old username in
  their markup and are not matched.
- **Non-ASCII usernames** are matched exactly in posts, quotes and topic
  lists; the markup-based rules (search, activity, avatars) only fold ASCII
  letter case.
- **Timing.** Hiding is applied in the same render as the content, but it runs
  in the browser after Discourse starts, so a brief flash on a slow device
  cannot be ruled out.
- **Refresh behaviour.** Ignoring or un-ignoring from a profile or user card
  updates open pages immediately. Changes made on another device, by an admin,
  or by an ignore expiring are picked up at the next full page load. In
  another already-open tab, lists update immediately but posts already drawn
  update when you next navigate.
- **No "show once".** Placeholders are plain text. To read hidden content,
  switch the preference off or un-ignore the user.
- **Staff.** Discourse does not let you ignore staff. If someone you ignored
  later becomes staff, Discourse shows their replies again while this
  component still hides their quotes and topics until you remove them from
  your list.
- The component sends nothing anywhere, adds no requests, and stores only the
  on/off flag described above.

## Compatibility

Written against Discourse `main` at commit `709839f7d2` (`2026.10.0-latest`,
2026-10-13). CI is configured for the `latest` branch and `release/2026.9`.
**No Discourse version is claimed as verified yet.**

The component relies on value transformers (`post-class`,
`topic-list-item-class`, `latest-topic-list-item-class`), wrapper plugin
outlets, the Glimmer post stream, `helper.renderGlimmer` and the
`virtual:theme` module. If a hook is missing, the affected surface is skipped
and a console warning starting with `[enhanced-ignore]` is logged; the rest
keeps working. Releases older than 2026.9 are not expected to work.

**After installing or upgrading Discourse**, run through the
[manual test checklist](docs/MANUAL_TEST_CHECKLIST.md) with a test member and
check the browser console for `[enhanced-ignore]` warnings.

## Verification status

<!-- verification:start -->

**Run by the author (2026-10-13)**

| Check | Where | Result |
| --- | --- | --- |
| ESLint, Stylelint, Prettier, type check (`pnpm lint`) | locally and in CI | pass |
| RuboCop and syntax_tree on the specs | locally and in CI | pass |
| Metadata / settings / locale-key validation (`pnpm validate`) | locally and in CI | pass |
| Unit tests for username matching, storage keys, generated selectors and hide decisions (14 tests) | locally under Node, and in CI inside Discourse (QUnit) | pass |
| English locale lint | CI | pass |
| System specs in `spec/system` (headless Chromium against a real Discourse, synthetic data) | CI only, on `latest` (`2026.10.0-latest`, `f9533b0a6d`) and `release/2026.9` (`2026.9.0`, `7322b6e390`) | 53 examples, 0 failures on each target ([run 38419054830](https://github.com/ieduer/discourse-enhanced-ignore/actions/runs/38419054830)); earlier runs failed on mistakes in the specs themselves, visible in the Actions history |

The system specs cover: the opt-in switch (default off, on/off, reload,
keyboard, per-account isolation, admin default, empty list, anonymous,
removal), topic lists (latest, new, unread, category, tag, categories +
latest, suggested, posters column, infinite scroll, expiry, mobile), quotes
(multiple, name-only, different case, nested both ways, unattributed and
malformed markup, mis-attributed expansion, live post and edit, far posts),
first posts, reply-to headers, the replies panel, full-page search, and
Discourse's own core-feature smoke tests with the component enabled.

**Not run by the author - awaiting verification on a live forum**

- Installation through the admin UI and attachment to a real theme.
- Everything in the [manual test checklist](docs/MANUAL_TEST_CHECKLIST.md):
  behaviour with real content, other theme components and plugins, real
  mobile devices, screen readers, dark mode, and timing/flash on slow devices.
- Ignoring someone from a user card while their posts are on screen, profile
  activity streams, topic-map avatars, personal messages.
- Any Discourse version other than the two CI targets above.

CI passing on two versions is evidence about those two versions in a test
environment. It is not a claim of production readiness.

<!-- verification:end -->

## Troubleshooting

| Symptom | Check |
| --- | --- |
| No "Enhanced ignore" section on Preferences > Users | The component must be included on the theme you are using. You only see it on your own preferences, when signed in. |
| Switched on but nothing is hidden | Is anyone in **Users > Ignored**? Muted users do not count. Reload once. |
| It was on yesterday and is off today | The choice is per browser. Site data may have been cleared, or you are in another browser or a private window. |
| A quote is still visible | It has no attribution, or names a different user. See the coverage table. |
| A topic is still listed | The ignored user replied in it but did not start it, or the list is provided by a plugin. |
| Something of your own layout broke | Disable the component (below) to confirm, then open an issue with the Discourse version and console output. |

## Disable, roll back, uninstall

- **One member:** untick the box on Preferences > Users.
- **Whole site, temporarily:** Admin > Appearance > Themes and components >
  Components > Enhanced Ignore > turn off **Enabled** (or remove it from the
  themes). Takes effect on the next page load.
- **Roll back a version:** delete the component and install it again from
  the git repository, entering the tag or branch you want in the install
  dialog's branch field.
- **Uninstall:** delete the component from the same page. No database
  migration, post, setting or user record is left behind. The only residue is
  the tiny on/off flag in each member's browser storage (keys starting with
  `discourse-enhanced-ignore:`), which is inert without the component.

## Development

```sh
git clone https://github.com/ieduer/discourse-enhanced-ignore
cd discourse-enhanced-ignore
pnpm install     # Node >= 22, pnpm 10
pnpm lint        # eslint, stylelint, prettier, type check
```

Checks that need no Discourse checkout:

```sh
pnpm test:unit   # pure-logic unit tests under plain Node
pnpm validate    # about.json, settings.yml and locale keys agree with the source
bundle exec rubocop . && bundle exec stree check Gemfile spec/**/*.rb
```

Checks that need Discourse (the same commands the official theme CI runs,
from a Discourse development checkout with this repository at `tmp/component`):

```sh
LOAD_PLUGINS=1 bin/turbo_rspec --format documentation tmp/component/spec/system

(cd tmp/component && git archive --format=tar.gz HEAD > ../../theme.tar.gz)
THEME_ARCHIVE=theme.tar.gz bundle exec rake themes:install:archive
bundle exec rake "themes:qunit[name,Enhanced Ignore]"
```

or, with the [`discourse_theme`](https://github.com/discourse/discourse_theme)
CLI: `discourse_theme rspec .`

Design notes, the research behind them and the extension points used are in
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Contributing

Issues and pull requests are welcome, especially compatibility reports for
other Discourse versions, themes and plugins. See
[CONTRIBUTING.md](CONTRIBUTING.md). Please use synthetic data in reports.

## License

[MIT](LICENSE). Tooling files derived from the official theme skeleton are
credited in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). No Discourse core
code is included.

This is an independent community project. It is not an official Discourse
component and is not endorsed by Civilized Discourse Construction Kit, Inc.
