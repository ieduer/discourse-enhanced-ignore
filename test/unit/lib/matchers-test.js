import { module, test } from "qunit";
import {
  POST_HIDDEN_CLASS,
  postClasses,
  REPLY_TO_HIDDEN_CLASS,
  TOPIC_HIDDEN_CLASS,
  topicAuthorUsername,
  topicClasses,
} from "../../../discourse/lib/enhanced-ignore/matchers";
import {
  buildIgnoredSet,
  isIgnoredUsername,
} from "../../../discourse/lib/enhanced-ignore/usernames";

function fakeState(usernames, { enabled = true } = {}) {
  const ignoredSet = buildIgnoredSet(usernames);
  const active = enabled && ignoredSet.size > 0;
  return {
    active,
    isIgnored: (username) => active && isIgnoredUsername(ignoredSet, username),
  };
}

function topicBy(...usernames) {
  return { posters: usernames.map((username) => ({ user: { username } })) };
}

module("Unit | Enhanced Ignore | matchers", function () {
  test("postClasses", function (assert) {
    const state = fakeState(["quinn"]);

    assert.deepEqual(postClasses(state, { username: "quinn" }), [
      POST_HIDDEN_CLASS,
    ]);
    assert.deepEqual(
      postClasses(state, {
        username: "alice",
        reply_to_user: { username: "Quinn" },
      }),
      [REPLY_TO_HIDDEN_CLASS],
      "a reply to an ignored user is kept; only its header is flagged"
    );
    assert.deepEqual(postClasses(state, { username: "quinn2" }), []);
    assert.deepEqual(postClasses(state, { username: "alice" }), []);
    assert.deepEqual(postClasses(state, {}), [], "missing metadata");
    assert.deepEqual(postClasses(state, null), [], "missing post");
    assert.deepEqual(
      postClasses(fakeState(["quinn"], { enabled: false }), {
        username: "quinn",
      }),
      [],
      "switched off"
    );
    assert.deepEqual(
      postClasses(fakeState([]), { username: "quinn" }),
      [],
      "empty list"
    );
  });

  test("topicAuthorUsername reads the original poster only", function (assert) {
    assert.strictEqual(topicAuthorUsername(topicBy("quinn", "alice")), "quinn");
    assert.strictEqual(topicAuthorUsername({ posters: [] }), null);
    assert.strictEqual(topicAuthorUsername({}), null);
    assert.strictEqual(topicAuthorUsername(null), null);
    assert.strictEqual(
      topicAuthorUsername({ posters: [{ user_id: 5 }] }),
      null,
      "poster without a resolved user"
    );
  });

  test("topicClasses", function (assert) {
    const state = fakeState(["quinn"]);

    assert.deepEqual(topicClasses(state, topicBy("quinn", "alice")), [
      TOPIC_HIDDEN_CLASS,
    ]);
    assert.deepEqual(
      topicClasses(state, topicBy("alice", "quinn")),
      [],
      "an ignored participant does not hide someone else's topic"
    );
    assert.deepEqual(topicClasses(state, topicBy("quinn2")), []);
    assert.deepEqual(topicClasses(state, {}), [], "list without posters");
    assert.deepEqual(
      topicClasses(fakeState(["quinn"], { enabled: false }), topicBy("quinn")),
      []
    );
  });
});
