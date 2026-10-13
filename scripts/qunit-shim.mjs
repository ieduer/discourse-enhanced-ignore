// Minimal QUnit-compatible surface on top of node:test, covering only the
// assertions the unit tests use.
import assert from "node:assert/strict";
import { describe, it } from "node:test";

const qunitAssert = {
  true: (value, message) => assert.strictEqual(value, true, message),
  false: (value, message) => assert.strictEqual(value, false, message),
  strictEqual: (actual, expected, message) =>
    assert.strictEqual(actual, expected, message),
  notStrictEqual: (actual, expected, message) =>
    assert.notStrictEqual(actual, expected, message),
  deepEqual: (actual, expected, message) =>
    assert.deepStrictEqual(actual, expected, message),
};

export function module(name, callback) {
  describe(name, () => callback());
}

export function test(name, callback) {
  it(name, () => callback(qunitAssert));
}
