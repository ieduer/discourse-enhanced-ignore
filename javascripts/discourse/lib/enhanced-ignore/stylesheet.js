// Generated rules for surfaces that have no class transformer or outlet but
// do expose the author through a `data-user-card="<username>"` attribute.
//
// The rules are rebuilt from the native ignore list, are empty while the
// feature is off, and never touch the DOM, so there is nothing to rescan when
// content is added by infinite scrolling or live updates.

export const MAX_GENERATED_USERNAMES = 300;

// Each entry maps an attribute selector to the element that should be hidden.
export const SURFACES = Object.freeze([
  // Full-page search results (one result = one post).
  (attr) => `.fps-result:has(> .author a${attr})`,
  // Profile activity: entries whose header avatar is the ignored user. The
  // header is targeted so that a "liked by" avatar never hides an entry.
  (attr) =>
    `.post-list.user-stream .post-list-item:has(> .post-list-item__header a.avatar-link${attr})`,
  // Participant avatars in topic lists and the topic map.
  (attr) => `.topic-list .posters a${attr}`,
  (attr) => `.latest-topic-list-item .topic-poster a${attr}`,
  (attr) => `.topic-map__users-list a${attr}`,
]);

// Usernames are restricted to word characters, dots and dashes (optionally
// Unicode letters). Anything else is skipped rather than escaped creatively.
export function attributeSelector(username) {
  if (
    typeof username !== "string" ||
    !/^[\p{L}\p{M}\p{N}_.-]+$/u.test(username)
  ) {
    return null;
  }

  // The `i` flag gives ASCII case-insensitive matching, which mirrors how
  // Discourse compares usernames for the default (ASCII) username rules.
  return `[data-user-card="${username}" i]`;
}

export function buildStylesheet(ignoredSet) {
  if (!ignoredSet || ignoredSet.size === 0) {
    return "";
  }

  const selectors = [];
  let count = 0;

  for (const username of ignoredSet) {
    if (count >= MAX_GENERATED_USERNAMES) {
      break;
    }

    const attr = attributeSelector(username);
    if (!attr) {
      continue;
    }

    count++;
    for (const surface of SURFACES) {
      selectors.push(surface(attr));
    }
  }

  if (selectors.length === 0) {
    return "";
  }

  return `${selectors.join(",\n")} {\n  display: none !important;\n}\n`;
}
