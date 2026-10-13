# frozen_string_literal: true

# Shared setup for the Enhanced Ignore system specs. Every account and every
# piece of content here is synthetic.
module EnhancedIgnoreHelpers
  QUOTE_PLACEHOLDER = "Quote hidden (ignored user)"
  POST_PLACEHOLDER = "Post hidden (ignored user)"
  TOGGLE = "#enhanced-ignore-toggle"

  def self.included(base)
    base.fab!(:viewer) do
      Fabricate(:user, username: "viewer", trust_level: TrustLevel[2], refresh_auto_groups: true)
    end
    base.fab!(:ignored) { Fabricate(:user, username: "quinn", refresh_auto_groups: true) }
    base.fab!(:lookalike) { Fabricate(:user, username: "quinn2", refresh_auto_groups: true) }
    base.fab!(:friend) { Fabricate(:user, username: "alice", refresh_auto_groups: true) }
  end

  def ignore!(target = ignored, by: viewer)
    Fabricate(:ignored_user, user: by, ignored_user: target)
  end

  def enable_for_everyone!
    component.update_setting(:enabled_by_default, true)
    component.save!
  end

  def stored_preferences
    page.evaluate_script(<<~JS)
      Object.fromEntries(
        Object.keys(localStorage)
          .filter((key) => key.startsWith("discourse-enhanced-ignore:"))
          .map((key) => [key, localStorage.getItem(key)])
      )
    JS
  end

  def topic_row(topic)
    ".topic-list-item[data-topic-id='#{topic.id}']"
  end
end
