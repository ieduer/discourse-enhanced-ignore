# Contributing

Thanks for helping. This is a small theme component; please keep changes
proportionate.

## Ground rules

- **The native Ignore list is the only source of truth.** No second blocklist,
  no Mute integration, no server calls to look up users.
- **Unknown authorship never hides content.** If a surface does not expose a
  reliable username, leave it alone and document the gap.
- **Match whole usernames only**, through `lib/enhanced-ignore/usernames.js`.
  No display names, substrings or text matching.
- **Use supported extension points**: value transformers, plugin outlets,
  `api.decorateCookedElement`. No widget APIs, monkey patches, polling,
  document-wide rescans or `MutationObserver`s.
- **Never mutate models or stored content**, and never mark anything as read.
- Every user-visible string goes in `locales/en.yml`.
- Use synthetic names and text in tests, screenshots and issues.

## Setup

```sh
pnpm install          # lint tooling (Node >= 22, pnpm 10)
bundle install        # rubocop / syntax_tree for the specs
pnpm lint             # eslint, stylelint, prettier, type check
```

## Tests

Unit tests live in `test/unit` (QUnit) and rendering tests in `spec/system`
(RSpec + Capybara + Playwright). Both run inside a Discourse checkout; the
README's "Development" section has the exact commands. A change to what is
hidden needs a system spec that shows both the hidden content and the
neighbouring content that must stay visible.

## Pull requests

- Describe the surface, the Discourse version you tested, and the extension
  point you used.
- Update the coverage matrix in `README.md` and add a `CHANGELOG.md` entry.
- CI must pass on both configured Discourse targets.
