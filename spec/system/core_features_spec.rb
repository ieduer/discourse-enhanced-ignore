# frozen_string_literal: true

# Runs Discourse's own smoke tests (login, likes, profile, topics, search)
# with the component installed and switched on for everyone, to catch
# regressions in core behaviour.
RSpec.describe "Enhanced Ignore - core features" do
  let!(:component) { upload_theme_component }

  before do
    component.update_setting(:enabled_by_default, true)
    component.save!
  end

  it_behaves_like "having working core features"
end
