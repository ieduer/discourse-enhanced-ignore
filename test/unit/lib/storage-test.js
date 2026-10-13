import { module, test } from "qunit";
import {
  parsePreference,
  readPreference,
  storageKey,
  writePreference,
} from "../../../discourse/lib/enhanced-ignore/storage";

function fakeStorage(initial = {}) {
  const data = new Map(Object.entries(initial));
  return {
    getItem: (key) => (data.has(key) ? data.get(key) : null),
    setItem: (key, value) => data.set(key, String(value)),
    data,
  };
}

const brokenStorage = {
  getItem() {
    throw new Error("blocked");
  },
  setItem() {
    throw new Error("blocked");
  },
};

module("Unit | Enhanced Ignore | storage", function () {
  test("storageKey isolates by site path and user id", function (assert) {
    assert.strictEqual(storageKey(7), "discourse-enhanced-ignore:v1:/:7");
    assert.strictEqual(
      storageKey(7, "/forum/"),
      "discourse-enhanced-ignore:v1:/forum/:7"
    );
    assert.notStrictEqual(storageKey(7), storageKey(8), "different users");
    assert.notStrictEqual(
      storageKey(7, "/a/"),
      storageKey(7, "/b/"),
      "different subfolder sites"
    );
    assert.strictEqual(storageKey(undefined), null, "anonymous");
    assert.strictEqual(storageKey(0), null, "invalid id");
    assert.strictEqual(storageKey("7"), null, "non-numeric id");
  });

  test("parsePreference only accepts its own values", function (assert) {
    assert.true(parsePreference("1"));
    assert.false(parsePreference("0"));
    assert.strictEqual(parsePreference(null), null);
    assert.strictEqual(parsePreference("true"), null);
    assert.strictEqual(parsePreference("garbage"), null);
  });

  test("read and write round-trip per key", function (assert) {
    const storage = fakeStorage();
    const mine = storageKey(7);
    const theirs = storageKey(8);

    assert.strictEqual(readPreference(mine, storage), null, "nothing stored");
    assert.true(writePreference(mine, true, storage));
    assert.true(readPreference(mine, storage));
    assert.strictEqual(
      readPreference(theirs, storage),
      null,
      "another account does not see it"
    );
    assert.true(writePreference(mine, false, storage));
    assert.false(readPreference(mine, storage));
  });

  test("degrades when storage is missing or blocked", function (assert) {
    const key = storageKey(7);

    assert.strictEqual(readPreference(key, null), null);
    assert.false(writePreference(key, true, null));
    assert.strictEqual(readPreference(key, brokenStorage), null);
    assert.false(writePreference(key, true, brokenStorage));
    assert.strictEqual(readPreference(null, fakeStorage()), null, "no key");
    assert.false(writePreference(null, true, fakeStorage()), "no key");
  });
});
