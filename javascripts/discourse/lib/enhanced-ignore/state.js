import { cached, tracked } from "@glimmer/tracking";
import { registerDestructor } from "@ember/destroyable";
import getURL from "discourse/lib/get-url";
import {
  parsePreference,
  readPreference,
  storageKey,
  writePreference,
} from "./storage";
import { buildIgnoredSet, isIgnoredUsername } from "./usernames";

const STATES = new WeakMap();

// One instance per application. It owns no copy of the ignore list: the
// native `currentUser.ignored_users` array stays the single source of truth
// and every getter below is derived from it through autotracking.
export default class EnhancedIgnoreState {
  static create(owner, options = {}) {
    const state = new EnhancedIgnoreState(owner, options);
    STATES.set(owner, state);
    return state;
  }

  static for(owner) {
    return owner ? STATES.get(owner) : undefined;
  }

  @tracked preference = null;
  @tracked persisted = true;

  #currentUser;
  #defaultEnabled;
  #key;

  constructor(owner, { defaultEnabled = false } = {}) {
    this.#currentUser = owner.lookup("service:current-user");
    this.#defaultEnabled = defaultEnabled === true;

    if (!this.#currentUser) {
      return;
    }

    this.#key = storageKey(this.#currentUser.id, getURL("/"));
    this.preference = readPreference(this.#key);

    // Keep several tabs of the same account in step. `storage` only fires in
    // other tabs, and only for this exact key, so the work is bounded.
    const onStorage = (event) => {
      if (event.key === this.#key) {
        this.preference = parsePreference(event.newValue);
      }
    };
    window.addEventListener("storage", onStorage);
    registerDestructor(owner, () => {
      window.removeEventListener("storage", onStorage);
      STATES.delete(owner);
    });
  }

  // False for anonymous visitors: there is no ignore list to extend.
  get available() {
    return !!this.#currentUser;
  }

  get enabled() {
    if (!this.available) {
      return false;
    }
    return this.preference ?? this.#defaultEnabled;
  }

  @cached
  get ignoredSet() {
    return buildIgnoredSet(
      this.#currentUser?.ignored_users,
      this.#currentUser?.username
    );
  }

  get ignoredCount() {
    return this.ignoredSet.size;
  }

  get active() {
    return this.enabled && this.ignoredSet.size > 0;
  }

  isIgnored(username) {
    return this.active && isIgnoredUsername(this.ignoredSet, username);
  }

  setEnabled(value) {
    if (!this.available) {
      return;
    }
    this.preference = value === true;
    this.persisted = writePreference(this.#key, this.preference);
  }
}
