import { module, test } from "qunit";
import {
  buildIgnoredSet,
  isIgnoredUsername,
  normalizeUsername,
} from "../../../discourse/lib/enhanced-ignore/usernames";

module("Unit | Enhanced Ignore | usernames", function () {
  test("normalizeUsername", function (assert) {
    assert.strictEqual(normalizeUsername("Quinn"), "quinn", "lower-cases");
    assert.strictEqual(normalizeUsername("  quinn "), "quinn", "trims");
    assert.strictEqual(
      normalizeUsername("Zoë"),
      "zoë",
      "applies NFC like Discourse's username_lower"
    );
    assert.strictEqual(normalizeUsername(""), null, "rejects empty strings");
    assert.strictEqual(normalizeUsername("   "), null, "rejects blanks");
    assert.strictEqual(normalizeUsername(null), null, "rejects null");
    assert.strictEqual(normalizeUsername(42), null, "rejects non-strings");
  });

  test("buildIgnoredSet", function (assert) {
    assert.strictEqual(buildIgnoredSet(undefined).size, 0, "missing list");
    assert.strictEqual(buildIgnoredSet(null).size, 0, "null list");
    assert.strictEqual(buildIgnoredSet("quinn").size, 0, "not an array");
    assert.strictEqual(buildIgnoredSet([]).size, 0, "empty list");

    const set = buildIgnoredSet(["Quinn", "quinn", null, "", "Sam"], "sam");
    assert.deepEqual([...set], ["quinn"], "dedupes, skips junk and self");
  });

  test("isIgnoredUsername matches whole usernames only", function (assert) {
    const set = buildIgnoredSet(["quinn"]);

    assert.true(isIgnoredUsername(set, "quinn"));
    assert.true(isIgnoredUsername(set, "QUINN"), "case-insensitive");
    assert.false(isIgnoredUsername(set, "quinn2"), "longer look-alike");
    assert.false(isIgnoredUsername(set, "quin"), "shorter look-alike");
    assert.false(isIgnoredUsername(set, "a_quinn"), "suffix look-alike");
    assert.false(isIgnoredUsername(set, "Quinn Smith"), "display name");
    assert.false(isIgnoredUsername(set, undefined), "missing metadata");
    assert.false(isIgnoredUsername(set, ""), "empty username");
    assert.false(isIgnoredUsername(new Set(), "quinn"), "empty list");
    assert.false(isIgnoredUsername(undefined, "quinn"), "no list");
  });
});
