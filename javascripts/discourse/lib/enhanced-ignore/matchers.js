// Pure decisions about what to hide. Every function returns "nothing" when
// identity information is missing: unknown authorship never hides content.

export const POST_HIDDEN_CLASS = "enhanced-ignore-post";
export const REPLY_TO_HIDDEN_CLASS = "enhanced-ignore-reply-to";
export const TOPIC_HIDDEN_CLASS = "enhanced-ignore-topic";
export const QUOTE_HIDDEN_CLASS = "enhanced-ignore-quote--hidden";
export const QUOTE_GUARD_CLASS = "enhanced-ignore-quote-guard";
export const COOKED_HIDDEN_CLASS = "enhanced-ignore-cooked";

export function postClasses(state, post) {
  const classes = [];

  if (!post || !state.active) {
    return classes;
  }

  if (state.isIgnored(post.username)) {
    classes.push(POST_HIDDEN_CLASS);
  }

  if (state.isIgnored(post.reply_to_user?.username)) {
    classes.push(REPLY_TO_HIDDEN_CLASS);
  }

  return classes;
}

// Topic-list payloads do not carry the topic's `user_id`. They do carry
// `posters`, whose first entry is always the original poster (the server
// builds the summary as [topic author, last poster, featured users]).
export function topicAuthorUsername(topic) {
  const first = topic?.posters?.[0];
  const username = first?.user?.username;
  return typeof username === "string" ? username : null;
}

export function topicClasses(state, topic) {
  if (!topic || !state.active) {
    return [];
  }

  return state.isIgnored(topicAuthorUsername(topic))
    ? [TOPIC_HIDDEN_CLASS]
    : [];
}
