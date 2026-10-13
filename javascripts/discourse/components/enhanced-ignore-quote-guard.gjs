import Component from "@glimmer/component";
import { modifier } from "ember-modifier";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";
import { QUOTE_HIDDEN_CLASS } from "../lib/enhanced-ignore/matchers";

// Keeps the hidden class on the quote in step with the member's ignore list
// and preference, and removes it again when the post is torn down.
const syncHiddenClass = modifier((element, [target, hidden]) => {
  target?.classList.toggle(QUOTE_HIDDEN_CLASS, hidden);
  return () => target?.classList.remove(QUOTE_HIDDEN_CLASS);
});

// Rendered next to every attributed quote through `helper.renderGlimmer`.
// `@data` is `{ state, aside, username }`.
export default class EnhancedIgnoreQuoteGuard extends Component {
  get hidden() {
    return this.args.data.state.isIgnored(this.args.data.username);
  }

  <template>
    <span
      class="enhanced-ignore-placeholder enhanced-ignore-placeholder--quote"
      role="note"
      {{syncHiddenClass @data.aside this.hidden}}
    >
      {{~#if this.hidden~}}
        {{i18n (themePrefix "placeholder.quote")}}
      {{~/if~}}
    </span>
  </template>
}
