# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-10-13

First public version. Not yet verified on a running Discourse instance; see
the README's "Verification status".

### Added

- Per-member opt-in switch on Preferences > Users, stored per site and account
  in the browser.
- Hides attributed quotes of ignored users (including nested quotes and quotes
  without a post reference) behind a neutral placeholder, keeping the
  surrounding post.
- Hides the avatar, names and body of posts by ignored users that Discourse
  still renders (topic starters, posts already on screen when the user is
  ignored).
- Hides the reply-to header that names an ignored user, their entries in
  expanded replies panels, and their posts inside expanded quotes.
- Hides topics started by ignored users in topic lists (latest, new, unread,
  top, category, tag, suggested, categories + latest).
- Hides full-page search results, profile activity entries and participant
  avatars attributed to ignored users.
- Manual test checklist, static configuration validator and a Node runner for
  the unit tests.
- `enabled_by_default` admin setting.
