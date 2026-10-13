import Component from "@glimmer/component";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";

// Shown in place of the body of a post whose author is ignored. The body
// itself, the avatar and the names are hidden by CSS keyed on the class the
// `post-class` transformer adds, so nothing here touches the post model.
export default class EnhancedIgnorePostPlaceholder extends Component {
  get hidden() {
    return this.args.state.isIgnored(this.args.post?.username);
  }

  <template>
    {{#if this.hidden}}
      <div
        class="enhanced-ignore-placeholder enhanced-ignore-placeholder--post"
        role="note"
      >
        {{i18n (themePrefix "placeholder.post")}}
      </div>
    {{/if}}
  </template>
}
