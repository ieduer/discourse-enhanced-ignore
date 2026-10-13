import { settings } from "virtual:theme";
import { apiInitializer } from "discourse/lib/api";
import EnhancedIgnorePostPlaceholder from "../components/enhanced-ignore-post-placeholder";
import EnhancedIgnorePreference from "../components/enhanced-ignore-preference";
import EnhancedIgnoreQuoteGuard from "../components/enhanced-ignore-quote-guard";
import EnhancedIgnoreStyles from "../components/enhanced-ignore-styles";
import {
  COOKED_HIDDEN_CLASS,
  postClasses,
  QUOTE_GUARD_CLASS,
  QUOTE_HIDDEN_CLASS,
  topicClasses,
} from "../lib/enhanced-ignore/matchers";
import EnhancedIgnoreState from "../lib/enhanced-ignore/state";

// A hook that is missing on the running Discourse version must only cost the
// surface it covers, never the rest of the component or the page.
function attempt(surface, callback) {
  try {
    callback();
  } catch (error) {
    // eslint-disable-next-line no-console
    console.warn(
      `[enhanced-ignore] "${surface}" is not supported on this Discourse version and was skipped.`,
      error
    );
  }
}

function decorateCooked(state, element, helper) {
  if (!state.enabled || !element?.querySelectorAll) {
    return;
  }

  // Embedded replies and expanded quotes render the body of another post.
  // Mark it when that post's author is ignored; scoped CSS decides where a
  // marked body is hidden.
  if (state.isIgnored(helper?.model?.username)) {
    element.classList.add(COOKED_HIDDEN_CLASS);
  }

  // Only quotes that carry an explicit attribution are considered. The same
  // quote can be visited twice (nested rendering), hence the sibling check.
  for (const aside of element.querySelectorAll("aside.quote[data-username]")) {
    if (aside.nextElementSibling?.classList.contains(QUOTE_GUARD_CLASS)) {
      continue;
    }

    // Discourse re-renders the body of a quote that links to a post and runs
    // this decorator again on the new copy, so anything nested in such a
    // quote is handled in that later pass, not on the copy being discarded.
    if (aside.parentElement?.closest("aside.quote[data-post]")) {
      continue;
    }

    const username = aside.dataset.username;
    const host = element.ownerDocument.createElement("div");
    host.className = QUOTE_GUARD_CLASS;
    aside.after(host);

    // Set the initial state synchronously so the attribution is not painted
    // before the guard component renders.
    if (state.isIgnored(username)) {
      aside.classList.add(QUOTE_HIDDEN_CLASS);
    }

    if (typeof helper?.renderGlimmer === "function") {
      helper.renderGlimmer(host, EnhancedIgnoreQuoteGuard, {
        state,
        aside,
        username,
      });
    }
  }
}

export default apiInitializer((api) => {
  const state = EnhancedIgnoreState.create(api.container, {
    defaultEnabled: settings.enabled_by_default,
  });

  // Anonymous visitors have no ignore list: register nothing at all.
  if (!state.available) {
    return;
  }

  attempt("preference control", () =>
    api.renderInOutlet(
      "user-custom-controls",
      <template>
        <EnhancedIgnorePreference
          @state={{state}}
          @model={{@outletArgs.model}}
        />
      </template>
    )
  );

  attempt("generated styles", () =>
    api.renderInOutlet(
      "above-site-header",
      <template><EnhancedIgnoreStyles @state={{state}} /></template>
    )
  );

  attempt("posts", () =>
    api.registerValueTransformer("post-class", ({ value, context }) => {
      const extra = postClasses(state, context.post);
      return extra.length ? [...value, ...extra] : value;
    })
  );

  attempt("post placeholder", () =>
    api.renderBeforeWrapperOutlet(
      "post-content-cooked-html",
      <template>
        <EnhancedIgnorePostPlaceholder
          @state={{state}}
          @post={{@outletArgs.post}}
        />
      </template>
    )
  );

  for (const name of [
    "topic-list-item-class",
    "latest-topic-list-item-class",
  ]) {
    attempt(name, () =>
      api.registerValueTransformer(name, ({ value, context }) => {
        const extra = topicClasses(state, context.topic);
        return extra.length ? [...value, ...extra] : value;
      })
    );
  }

  attempt("quotes", () =>
    api.decorateCookedElement(
      (element, helper) => decorateCooked(state, element, helper),
      { onlyStream: true }
    )
  );
});
