<!--
DRAFT - NOT POSTED. Intended for meta.discourse.org, category "Theme component".
Before posting:
  1. Complete docs/MANUAL_TEST_CHECKLIST.md on a real forum and replace the
     "Status" paragraph and the "Tested on" table with what was actually seen.
  2. Add real screenshots (synthetic accounts only) where marked.
  3. Re-check that the repository link and install steps still match.
-->

# Enhanced Ignore - extend your Ignore list to quotes, reply previews and topic lists

| | |
| - | - |
| :information_source: | **Summary** Lets each member opt in to hiding more of the content of users they already ignore: attributed quotes, reply-to headers, topic starters and topics in lists. |
| :hammer_and_wrench: | **Repository** https://github.com/ieduer/discourse-enhanced-ignore |
| :question: | **Install guide** [How to install a theme or theme component](https://meta.discourse.org/t/how-do-i-install-a-theme-or-theme-component/63682) |
| :open_book: | **New to Discourse themes?** [Beginner's guide to using Discourse Themes](https://meta.discourse.org/t/beginners-guide-to-using-discourse-themes/91966) |

**Status: early release (0.1.0).** [REPLACE BEFORE POSTING with the real state.
As drafted: the component passes linting, type checks and unit tests and was
written against the current Discourse source, but has only been verified on
the forums listed under "Tested on" below.]

## The problem

Discourse's Ignore feature removes an ignored user's replies from topics and
stops their notifications. Their content still reaches you in a few places:

- other people quoting them - the quote box still shows their avatar and
  name, and `[quote="name"]` quotes without a post link are shown in full;
- the "in reply to" tab on posts that answer them, and the replies panel;
- topics they started, in Latest / New / Unread / category / tag lists and in
  suggested topics;
- the first post of a topic they started (body replaced, avatar and name kept);
- full-page search results.

There is an earlier component for one of these,
[Hide ignored users' topics](https://meta.discourse.org/t/hide-ignored-users-topics/276420),
and a [discussion about replies](https://meta.discourse.org/t/need-help-with-code-from-core-ignore-user/327675).
Enhanced Ignore is a separate, new implementation that covers the set above
with current APIs (value transformers, plugin outlets, `decorateCookedElement`).

## What it does

- **Personal and opt-in.** Each member switches it on for themselves under
  **Preferences > Users > Enhanced ignore**. Nothing changes for anyone else,
  nothing is deleted, moderation is not involved. Admins can optionally make
  it on-by-default with one setting; members can still opt out.
- **Uses the native Ignored list.** No second blocklist. Mute is not touched.
  Adding, removing and expiry work as they always did.
- **Hides the quote, keeps the post.** A quote attributed to an ignored user
  becomes one neutral line - "Quote hidden (ignored user)" - and the rest of
  the other author's post stays. Nested quotes are handled so an ignored inner
  quote does not take the outer text with it.
- **Does not chase replies.** A post answering an ignored user is kept; only
  the reply-to header naming them is hidden.
- **Topic lists.** Topics *started* by ignored users are hidden. Topics they
  merely replied in stay.

[SCREENSHOTS - add real captures here: a post with a hidden quote, a topic
list before/after, the Preferences > Users switch, one mobile view.]

## Install

1. Admin > Appearance > Themes and components > Components > **Install** >
   **From a git repository**
2. `https://github.com/ieduer/discourse-enhanced-ignore`
3. Add the component to the themes your members use.

Members need to be allowed to use Ignore at all (site setting
`ignore allowed groups`).

**Setting:** `enabled_by_default` (off) - switch Enhanced Ignore on for members
who have not chosen yet.

## Tested on

[REPLACE BEFORE POSTING with real results.]

| Discourse | How | Result |
| --- | --- | --- |
| [version] | manual checklist on a live forum | [result] |
| `2026.10.0-latest` (`f9533b0a6d`) and `2026.9.0` (`7322b6e390`) | repository CI: lint, unit tests, 53 system examples per version in a test environment | pass on 2026-10-13 ([run](https://github.com/ieduer/discourse-enhanced-ignore/actions/runs/38419054830)) - [re-check the latest run before posting] |

The full coverage table (implemented / partial / native / not handled) is in
the [README](https://github.com/ieduer/discourse-enhanced-ignore#coverage).

## Please read: limits

- Hiding happens **in your browser**. The content is still on the server, in
  the API and page data, in emails, push notifications, feeds and other apps.
  This is a display preference, **not** a block, a safety tool or a privacy
  guarantee.
- The on/off choice is stored **per browser** (a theme component cannot add an
  account option), so it is not synced between devices. The ignore list itself
  stays in your account as usual.
- Quote attribution is whatever the quoting author typed. Unattributed quotes,
  copy-pasted text, paraphrases, screenshots and embeds are not detected, and
  there is no text matching or AI involved.
- Hidden topics still count in "New (n)" and page sizes; nothing is ever
  marked as read for you.
- Not covered: chat, the header quick-search dropdown, the review queue and
  admin pages (deliberately), plugin-provided lists, and the nested replies
  view, which has its own native handling.
- There is no "show once" button; switch the preference off or un-ignore to
  read something.

## Uninstall

Disable or delete the component in the admin. It makes no database changes.
The only leftover is a tiny on/off flag in each member's browser storage,
which does nothing without the component.

## Feedback wanted

Compatibility reports are especially welcome: other Discourse versions, themes
that restyle the topic list or posts, and plugins that add their own lists.
Please use the
[issue templates](https://github.com/ieduer/discourse-enhanced-ignore/issues/new/choose)
or reply here, with the Discourse version and - please - synthetic usernames
only. There is a
[manual test checklist](https://github.com/ieduer/discourse-enhanced-ignore/blob/main/docs/MANUAL_TEST_CHECKLIST.md)
if you want to try it systematically.

This is an independent community component, MIT licensed, and not an official
Discourse project.
