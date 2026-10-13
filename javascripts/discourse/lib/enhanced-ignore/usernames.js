// Username matching helpers.
//
// Discourse treats usernames as unique after `unicode_normalize.downcase`
// (see `User.normalize_username`), so we compare on the same normal form.
// Only whole usernames are ever compared: no substrings, no display names.

export function normalizeUsername(value) {
  if (typeof value !== "string") {
    return null;
  }

  const trimmed = value.trim();
  if (trimmed === "") {
    return null;
  }

  return trimmed.normalize("NFC").toLowerCase();
}

export function buildIgnoredSet(usernames, selfUsername) {
  const result = new Set();

  if (!Array.isArray(usernames)) {
    return result;
  }

  const self = normalizeUsername(selfUsername);

  for (const username of usernames) {
    const normalized = normalizeUsername(username);
    if (normalized && normalized !== self) {
      result.add(normalized);
    }
  }

  return result;
}

export function isIgnoredUsername(ignoredSet, username) {
  if (!ignoredSet || ignoredSet.size === 0) {
    return false;
  }

  const normalized = normalizeUsername(username);
  return normalized !== null && ignoredSet.has(normalized);
}
