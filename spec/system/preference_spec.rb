# frozen_string_literal: true

require_relative "support/enhanced_ignore_helpers"

RSpec.describe "Enhanced Ignore - member preference" do
  include EnhancedIgnoreHelpers

  let!(:component) { upload_theme_component }

  fab!(:ignored_topic) { Fabricate(:post, user: ignored).topic }
  fab!(:friend_topic) { Fabricate(:post, user: friend).topic }

  let(:preferences_path) { "/u/#{viewer.username}/preferences/users" }

  it "does nothing for anonymous visitors" do
    enable_for_everyone!

    visit("/latest")

    expect(page).to have_css(topic_row(friend_topic))
    expect(page).to have_css(topic_row(ignored_topic))
    expect(page).to have_no_css("#enhanced-ignore-generated-styles", visible: :all)
  end

  it "is off until the member opts in" do
    ignore!
    sign_in(viewer)

    visit("/latest")
    expect(page).to have_css(topic_row(friend_topic))
    expect(page).to have_css(topic_row(ignored_topic))

    visit(preferences_path)
    expect(page).to have_css(TOGGLE)
    expect(page).to have_no_checked_field("enhanced-ignore-toggle")
    expect(page).to have_css(".enhanced-ignore-preference__status", text: "Enhanced ignore is off.")
  end

  it "can be switched on and off from Preferences > Users and is remembered" do
    ignore!
    sign_in(viewer)
    visit(preferences_path)

    check("enhanced-ignore-toggle")
    expect(page).to have_css(
      ".enhanced-ignore-preference__status[role='status']",
      text: "Enhanced ignore is on for 1 ignored user.",
    )
    expect(stored_preferences.values).to eq(["1"])

    # Applies on in-app navigation, without a reload.
    find("#site-logo").click
    expect(page).to have_css(topic_row(friend_topic))
    expect(page).to have_no_css(topic_row(ignored_topic))

    # Survives a full reload.
    page.refresh
    expect(page).to have_css(topic_row(friend_topic))
    expect(page).to have_no_css(topic_row(ignored_topic))

    visit(preferences_path)
    expect(page).to have_checked_field("enhanced-ignore-toggle")
    uncheck("enhanced-ignore-toggle")
    expect(stored_preferences.values).to eq(["0"])

    find("#site-logo").click
    expect(page).to have_css(topic_row(ignored_topic))
  end

  it "can be operated with the keyboard and exposes an accessible name and description" do
    sign_in(viewer)
    visit(preferences_path)

    toggle = find(TOGGLE)
    expect(toggle["aria-describedby"]).to eq("enhanced-ignore-instructions")
    expect(page).to have_css("label[for='enhanced-ignore-toggle']", text: "Also hide quotes")
    expect(page).to have_css("#enhanced-ignore-instructions", text: "only changes what you see")

    toggle.send_keys(:space)
    expect(page).to have_checked_field("enhanced-ignore-toggle")
    expect(page).to have_css(
      ".enhanced-ignore-preference__status",
      text: "Your Ignored list is empty, so nothing is hidden.",
    )
  end

  it "keeps the choice separate for each account in the same browser" do
    ignore!
    ignore!(ignored, by: friend)

    sign_in(viewer)
    visit(preferences_path)
    check("enhanced-ignore-toggle")
    expect(stored_preferences.keys).to contain_exactly(
      "discourse-enhanced-ignore:v1:/:#{viewer.id}",
    )

    sign_in(friend)
    visit("/latest")
    expect(page).to have_css(topic_row(ignored_topic))

    visit("/u/#{friend.username}/preferences/users")
    expect(page).to have_css(TOGGLE)
    expect(page).to have_no_checked_field("enhanced-ignore-toggle")
  end

  it "lets a member opt out when the admin enabled it by default" do
    enable_for_everyone!
    ignore!
    sign_in(viewer)

    visit("/latest")
    expect(page).to have_css(topic_row(friend_topic))
    expect(page).to have_no_css(topic_row(ignored_topic))

    visit(preferences_path)
    expect(page).to have_checked_field("enhanced-ignore-toggle")
    uncheck("enhanced-ignore-toggle")

    find("#site-logo").click
    expect(page).to have_css(topic_row(ignored_topic))
  end

  it "hides nothing when the ignore list is empty" do
    enable_for_everyone!
    sign_in(viewer)

    visit("/latest")

    expect(page).to have_css(topic_row(friend_topic))
    expect(page).to have_css(topic_row(ignored_topic))
    expect(page).to have_no_css("#enhanced-ignore-generated-styles", visible: :all)
  end

  it "is not offered when viewing another member's preferences as staff" do
    admin = Fabricate(:admin)
    sign_in(admin)

    visit(preferences_path)

    expect(page).to have_css(".control-label", text: "Users")
    expect(page).to have_no_css(TOGGLE)
  end

  it "leaves no trace once the component is removed" do
    enable_for_everyone!
    ignore!
    sign_in(viewer)
    visit("/latest")
    expect(page).to have_no_css(topic_row(ignored_topic))

    component.destroy!
    page.refresh

    expect(page).to have_css(topic_row(friend_topic))
    expect(page).to have_css(topic_row(ignored_topic))
    visit(preferences_path)
    expect(page).to have_css(".control-label", text: "Users")
    expect(page).to have_no_css(TOGGLE)
  end
end
