import { module, test } from "qunit";
import {
  attributeSelector,
  buildStylesheet,
  MAX_GENERATED_USERNAMES,
  SURFACES,
} from "../../../discourse/lib/enhanced-ignore/stylesheet";

module("Unit | Enhanced Ignore | stylesheet", function () {
  test("attributeSelector only emits safe exact-match selectors", function (assert) {
    assert.strictEqual(
      attributeSelector("quinn"),
      '[data-user-card="quinn" i]'
    );
    assert.strictEqual(
      attributeSelector("a.b-c_1"),
      '[data-user-card="a.b-c_1" i]'
    );
    assert.strictEqual(
      attributeSelector("zoë"),
      '[data-user-card="zoë" i]',
      "unicode usernames"
    );
    assert.strictEqual(attributeSelector('x"] , * {'), null, "quote injection");
    assert.strictEqual(attributeSelector("a b"), null, "whitespace");
    assert.strictEqual(attributeSelector("a\\b"), null, "backslash");
    assert.strictEqual(attributeSelector(""), null, "empty");
    assert.strictEqual(attributeSelector(null), null, "null");
  });

  test("buildStylesheet is empty without usable usernames", function (assert) {
    assert.strictEqual(buildStylesheet(undefined), "");
    assert.strictEqual(buildStylesheet(new Set()), "");
    assert.strictEqual(buildStylesheet(new Set(['bad"name'])), "");
  });

  test("buildStylesheet emits one rule covering every surface", function (assert) {
    const css = buildStylesheet(new Set(["quinn", "sam"]));

    assert.strictEqual(
      css.match(/\{/g).length,
      1,
      "a single declaration block"
    );
    assert.strictEqual(
      css.match(/data-user-card="quinn" i/g).length,
      SURFACES.length
    );
    assert.strictEqual(
      css.match(/data-user-card="sam" i/g).length,
      SURFACES.length
    );
    assert.true(css.includes("display: none !important"));
    assert.false(css.includes("quinn2"), "no prefix matching");

    assert.strictEqual(css.match(/\}/g).length, 1, "block is closed once");
    assert.false(/[<;}]/.test(css.split("{")[0]), "selectors only");
  });

  test("buildStylesheet bounds its output", function (assert) {
    const many = new Set();
    for (let index = 0; index < MAX_GENERATED_USERNAMES + 50; index++) {
      many.add(`user${index}`);
    }

    const css = buildStylesheet(many);
    const selectors = css.split("{")[0].split(",\n");

    assert.strictEqual(
      selectors.length,
      MAX_GENERATED_USERNAMES * SURFACES.length
    );
  });
});
