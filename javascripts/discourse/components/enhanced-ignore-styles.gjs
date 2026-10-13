import Component from "@glimmer/component";
import { modifier } from "ember-modifier";
import { buildStylesheet } from "../lib/enhanced-ignore/stylesheet";

const STYLE_ID = "enhanced-ignore-generated-styles";

// Owns a single <style> element in <head>. It is rewritten only when the
// generated text changes and removed when the component is destroyed.
const syncStylesheet = modifier((element, [css]) => {
  let style = document.getElementById(STYLE_ID);

  if (!css) {
    style?.remove();
    return;
  }

  if (!style) {
    style = document.createElement("style");
    style.id = STYLE_ID;
    document.head.append(style);
  }

  if (style.textContent !== css) {
    style.textContent = css;
  }

  return () => document.getElementById(STYLE_ID)?.remove();
});

export default class EnhancedIgnoreStyles extends Component {
  get css() {
    const state = this.args.state;
    return state.active ? buildStylesheet(state.ignoredSet) : "";
  }

  <template>
    <span
      class="enhanced-ignore-styles-host"
      hidden
      {{syncStylesheet this.css}}
    ></span>
  </template>
}
