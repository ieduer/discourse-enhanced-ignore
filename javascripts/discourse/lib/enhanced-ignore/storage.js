// Browser-local persistence for the per-member preference.
//
// A theme component cannot add an account-level user option, so the choice is
// stored in `localStorage`. `localStorage` is already isolated per origin; the
// key additionally carries the site base path (subfolder installs) and the
// numeric user id, so two accounts sharing a browser never read each other's
// choice.

const PREFIX = "discourse-enhanced-ignore";
const VERSION = "v1";

export function storageKey(userId, basePath = "/") {
  if (!Number.isInteger(userId) || userId <= 0) {
    return null;
  }

  const path = typeof basePath === "string" && basePath !== "" ? basePath : "/";
  return `${PREFIX}:${VERSION}:${path}:${userId}`;
}

function defaultStorage() {
  try {
    return window.localStorage;
  } catch {
    return null;
  }
}

// Returns true, false, or null when nothing (valid) is stored.
export function parsePreference(raw) {
  if (raw === "1") {
    return true;
  }
  if (raw === "0") {
    return false;
  }
  return null;
}

export function readPreference(key, storage = defaultStorage()) {
  if (!key || !storage) {
    return null;
  }

  try {
    return parsePreference(storage.getItem(key));
  } catch {
    return null;
  }
}

// Returns false when the browser refused the write (private mode, quota,
// blocked site data), so the UI can say the choice will not be remembered.
export function writePreference(key, value, storage = defaultStorage()) {
  if (!key || !storage) {
    return false;
  }

  try {
    storage.setItem(key, value ? "1" : "0");
    return true;
  } catch {
    return false;
  }
}
