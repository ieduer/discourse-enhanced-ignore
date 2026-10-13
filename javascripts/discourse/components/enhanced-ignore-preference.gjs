import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";

// Per-member switch, rendered on Preferences > Users right below the native
// "Ignored" list. Only shown on the member's own preferences.
export default class EnhancedIgnorePreference extends Component {
  @service currentUser;

  get shouldShow() {
    return (
      this.args.state.available &&
      this.currentUser &&
      this.args.model?.id === this.currentUser.id
    );
  }

  get statusText() {
    const state = this.args.state;

    if (!state.enabled) {
      return i18n(themePrefix("preference.status_off"));
    }
    if (state.ignoredCount === 0) {
      return i18n(themePrefix("preference.status_empty"));
    }
    return i18n(themePrefix("preference.status_on"), {
      count: state.ignoredCount,
    });
  }

  @action
  toggle(event) {
    this.args.state.setEnabled(event.target.checked);
  }

  <template>
    {{#if this.shouldShow}}
      <div
        class="control-group enhanced-ignore-preference"
        data-setting-name="enhanced-ignore"
      >
        <label class="control-label">
          {{i18n (themePrefix "preference.title")}}
        </label>
        <div class="controls">
          <label class="checkbox-label" for="enhanced-ignore-toggle">
            <input
              id="enhanced-ignore-toggle"
              type="checkbox"
              checked={{@state.enabled}}
              aria-describedby="enhanced-ignore-instructions"
              {{on "change" this.toggle}}
            />
            {{i18n (themePrefix "preference.label")}}
          </label>
        </div>
        <div class="instructions" id="enhanced-ignore-instructions">
          {{i18n (themePrefix "preference.instructions")}}
        </div>
        <div
          class="enhanced-ignore-preference__status"
          role="status"
          aria-live="polite"
        >
          {{this.statusText}}
          {{#unless @state.persisted}}
            {{i18n (themePrefix "preference.not_persisted")}}
          {{/unless}}
        </div>
        {{#unless this.currentUser.can_ignore_users}}
          <div class="instructions enhanced-ignore-preference__ineligible">
            {{i18n (themePrefix "preference.cannot_ignore")}}
          </div>
        {{/unless}}
      </div>
    {{/if}}
  </template>
}
