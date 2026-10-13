# frozen_string_literal: true

require_relative "support/enhanced_ignore_helpers"

RSpec.describe "Enhanced Ignore - topic lists" do
  include EnhancedIgnoreHelpers

  let!(:component) { upload_theme_component }

  fab!(:category)
  fab!(:tag)

  fab!(:ignored_topic) do
    Fabricate(
      :post,
      user: ignored,
      topic: Fabricate(:topic, user: ignored, category:, tags: [tag]),
    ).topic
  end
  fab!(:lookalike_topic) do
    Fabricate(
      :post,
      user: lookalike,
      topic: Fabricate(:topic, user: lookalike, category:, tags: [tag]),
    ).topic
  end
  fab!(:friend_topic) do
    Fabricate(
      :post,
      user: friend,
      topic: Fabricate(:topic, user: friend, category:, tags: [tag]),
    ).topic
  end
  # A topic by a non-ignored author in which the ignored user merely replied.
  fab!(:replied_topic) do
    topic = Fabricate(:topic, user: friend, category:, tags: [tag])
    Fabricate(:post, user: friend, topic:)
    Fabricate(:post, user: ignored, topic:)
    topic
  end

  before do
    SiteSetting.tagging_enabled = true
    enable_for_everyone!
    ignore!
    sign_in(viewer)
  end

  def expect_filtered_list
    expect(page).to have_css(topic_row(friend_topic))
    expect(page).to have_css(topic_row(lookalike_topic))
    expect(page).to have_css(topic_row(replied_topic))
    expect(page).to have_no_css(topic_row(ignored_topic))
  end

  %w[/latest /new /unread].each do |path|
    it "hides ignored users' topics on #{path} but keeps look-alike usernames" do
      if path == "/unread"
        [ignored_topic, lookalike_topic, friend_topic, replied_topic].each do |topic|
          TopicUser.change(
            viewer.id,
            topic.id,
            notification_level: TopicUser.notification_levels[:tracking],
            last_read_post_number: 0,
          )
          TopicUser.where(user: viewer, topic:).update_all(last_read_post_number: 0)
          Fabricate(:post, topic:, user: friend)
        end
        TopicUser.where(user: viewer).update_all(last_read_post_number: 1)
      end

      visit(path)

      expect_filtered_list
    end
  end

  it "hides them on category and tag pages" do
    visit("/c/#{category.slug}/#{category.id}")
    expect_filtered_list

    visit("/tag/#{tag.name}")
    expect_filtered_list
  end

  it "hides them in the categories + latest layout" do
    SiteSetting.desktop_category_page_style = "categories_and_latest_topics"

    visit("/categories")

    expect(page).to have_css(".latest-topic-list-item[data-topic-id='#{friend_topic.id}']")
    expect(page).to have_css(".latest-topic-list-item[data-topic-id='#{lookalike_topic.id}']")
    expect(page).to have_no_css(".latest-topic-list-item[data-topic-id='#{ignored_topic.id}']")
  end

  it "hides them in suggested topics below a topic" do
    visit("/t/#{friend_topic.slug}/#{friend_topic.id}")

    expect(page).to have_css(".more-topics__container")
    within(".more-topics__container") do
      expect(page).to have_css(topic_row(lookalike_topic))
      expect(page).to have_no_css(topic_row(ignored_topic))
    end
  end

  it "removes the ignored user's avatar from another topic's posters column" do
    visit("/latest")

    within(topic_row(replied_topic)) do
      expect(page).to have_css(".posters a[data-user-card='#{friend.username}']")
      expect(page).to have_no_css(".posters a[data-user-card='#{ignored.username}']")
    end
  end

  it "keeps filtering topics that arrive through infinite scrolling" do
    extra =
      Fabricate
        .times(35, :topic, user: friend)
        .each { |topic| Fabricate(:post, topic:, user: friend) }
    late_ignored = Fabricate(:post, user: ignored, topic: Fabricate(:topic, user: ignored)).topic
    late_friend = Fabricate(:post, user: friend, topic: Fabricate(:topic, user: friend)).topic
    # Push both below the first page.
    Topic.where(id: [late_ignored.id, late_friend.id]).update_all(bumped_at: 2.years.ago)

    visit("/latest")
    expect(page).to have_css(topic_row(extra.last))
    expect(page).to have_no_css(topic_row(late_friend))

    page.execute_script("window.scrollTo(0, document.body.scrollHeight)")

    expect(page).to have_css(topic_row(late_friend))
    expect(page).to have_no_css(topic_row(late_ignored))
    expect(page).to have_css("#{topic_row(late_ignored)}.enhanced-ignore-topic", visible: :hidden)
  end

  it "picks up a new ignore on reload and an un-ignore from the profile without a reload" do
    visit("/latest")
    expect(page).to have_css(topic_row(lookalike_topic))

    ignore!(lookalike)
    page.refresh
    expect(page).to have_css(topic_row(friend_topic))
    expect(page).to have_no_css(topic_row(lookalike_topic))

    visit("/u/#{lookalike.username}/summary")
    find(".user-notifications-dropdown").click
    find(".select-kit-row[data-value='changeToNormal']").click

    find("#site-logo").click
    expect(page).to have_css(topic_row(lookalike_topic))
    expect(page).to have_no_css(topic_row(ignored_topic))
  end

  it "shows the topics again after the ignore expires and the page is reloaded" do
    visit("/latest")
    expect(page).to have_no_css(topic_row(ignored_topic))

    IgnoredUser.where(user: viewer).update_all(expiring_at: 1.minute.ago)
    Jobs::PurgeExpiredIgnoredUsers.new.execute({})
    page.refresh

    expect(page).to have_css(topic_row(ignored_topic))
  end

  it "hides them in the mobile topic list", mobile: true do
    visit("/latest")

    expect_filtered_list
  end
end
