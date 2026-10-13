# frozen_string_literal: true

require_relative "support/enhanced_ignore_helpers"

RSpec.describe "Enhanced Ignore - posts, reply previews and other surfaces" do
  include EnhancedIgnoreHelpers

  let!(:component) { upload_theme_component }

  before { ignore! }

  def post_selector(post)
    "#post_#{post.post_number}"
  end

  context "with a topic started by an ignored user" do
    fab!(:topic) { Fabricate(:topic, user: ignored) }
    fab!(:first_post) { Fabricate(:post, topic:, user: ignored, raw: "Opening secret words.") }
    fab!(:reply) { Fabricate(:post, topic:, user: friend, raw: "A legitimate reply from a friend.") }

    it "hides the author's identity and body but keeps other people's replies" do
      enable_for_everyone!
      sign_in(viewer)

      visit("/t/#{topic.slug}/#{topic.id}")

      within(post_selector(first_post)) do
        expect(page).to have_css(
          ".enhanced-ignore-placeholder--post[role='note']",
          text: EnhancedIgnoreHelpers::POST_PLACEHOLDER,
        )
        expect(page).to have_no_content("Opening secret words.")
        expect(page).to have_no_css(".topic-avatar img.avatar", visible: :visible)
        expect(page).to have_no_css(".names a", text: "quinn", visible: :visible)
      end

      within(post_selector(reply)) do
        expect(page).to have_content("A legitimate reply from a friend.")
        expect(page).to have_css(".names a", text: "alice")
        expect(page).to have_css(".topic-avatar img.avatar")
      end

      # Post numbering and navigation are untouched.
      expect(page).to have_css("#post_1")
      expect(page).to have_css("#post_2")
    end

    it "shows Discourse's native treatment when the member has not opted in" do
      sign_in(viewer)

      visit("/t/#{topic.slug}/#{topic.id}")

      within(post_selector(first_post)) do
        expect(page).to have_no_css(".enhanced-ignore-placeholder--post")
        expect(page).to have_css(".names a", text: "quinn")
      end
    end
  end

  context "with replies to and from an ignored user" do
    fab!(:topic) { Fabricate(:topic, user: viewer) }
    fab!(:first_post) { Fabricate(:post, topic:, user: viewer, raw: "The viewer opens a topic.") }
    fab!(:ignored_reply) do
      Fabricate(:post, topic:, user: ignored, reply_to_post_number: 1, raw: "Ignored reply words.")
    end
    fab!(:friend_reply) do
      Fabricate(:post, topic:, user: friend, reply_to_post_number: 1, raw: "Friendly reply words.")
    end
    fab!(:filler) do
      Fabricate(:post, topic:, user: lookalike, raw: "An unrelated post in between.")
    end
    fab!(:reply_to_ignored) do
      Fabricate(
        :post,
        topic:,
        user: friend,
        reply_to_post_number: ignored_reply.post_number,
        raw: "Answering the ignored user, still a legitimate post.",
      )
    end

    before do
      SiteSetting.suppress_reply_directly_above = false
      # Fabricated posts skip the bookkeeping that PostCreator does for replies.
      [ignored_reply, friend_reply].each { |reply| PostReply.create!(post: first_post, reply:) }
      first_post.update!(reply_count: 2)
    end

    it "keeps a reply to an ignored user but drops the reply-to header" do
      enable_for_everyone!
      sign_in(viewer)

      visit("/t/#{topic.slug}/#{topic.id}")

      within(post_selector(reply_to_ignored)) do
        expect(page).to have_content("Answering the ignored user, still a legitimate post.")
        expect(page).to have_css(".names a", text: "alice")
        expect(page).to have_no_css(".reply-to-tab", visible: :visible)
      end

      within(post_selector(friend_reply)) do
        expect(page).to have_css(".reply-to-tab", text: "viewer")
      end

      expect(page).to have_no_content("Ignored reply words.")
    end

    it "leaves the reply-to header alone when the member has not opted in" do
      sign_in(viewer)

      visit("/t/#{topic.slug}/#{topic.id}")

      within(post_selector(reply_to_ignored)) do
        expect(page).to have_css(".reply-to-tab", text: "quinn")
      end
    end

    it "omits the ignored user's entry from an expanded replies panel" do
      enable_for_everyone!
      sign_in(viewer)

      visit("/t/#{topic.slug}/#{topic.id}")

      within(post_selector(first_post)) do
        find(".show-replies").click

        expect(page).to have_css(".embedded-posts .reply", text: "Friendly reply words.")
        expect(page).to have_no_css(".embedded-posts .reply", text: "quinn", visible: :visible)
        expect(page).to have_no_css(
          ".embedded-posts .reply[data-post-id='#{ignored_reply.id}']",
          visible: :visible,
        )
      end
    end
  end

  context "with full-page search" do
    fab!(:ignored_hit) do
      Fabricate(:post, user: ignored, raw: "A xylophonic sentence by the ignored user.")
    end
    fab!(:friend_hit) { Fabricate(:post, user: friend, raw: "A xylophonic sentence by a friend.") }

    before do
      SearchIndexer.enable
      SearchIndexer.index(ignored_hit.topic, force: true)
      SearchIndexer.index(friend_hit.topic, force: true)
      SearchIndexer.index(ignored_hit, force: true)
      SearchIndexer.index(friend_hit, force: true)
    end

    after { SearchIndexer.disable }

    it "hides results whose author is ignored" do
      enable_for_everyone!
      sign_in(viewer)

      visit("/search?q=xylophonic")

      expect(page).to have_css(".fps-result", text: "by a friend")
      expect(page).to have_no_css(".fps-result", text: "by the ignored user", visible: :visible)
    end

    it "shows every result when the member has not opted in" do
      sign_in(viewer)

      visit("/search?q=xylophonic")

      expect(page).to have_css(".fps-result", text: "by a friend")
      expect(page).to have_css(".fps-result", text: "by the ignored user")
    end
  end
end
