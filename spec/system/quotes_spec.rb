# frozen_string_literal: true

require_relative "support/enhanced_ignore_helpers"

RSpec.describe "Enhanced Ignore - quotes" do
  include EnhancedIgnoreHelpers

  let!(:component) { upload_theme_component }

  fab!(:topic) { Fabricate(:topic, user: friend) }
  fab!(:first_post) { Fabricate(:post, topic:, user: friend, raw: "Opening post by a friend.") }
  fab!(:ignored_post) do
    Fabricate(:post, topic:, user: ignored, raw: "Original secret words from the ignored user.")
  end
  fab!(:lookalike_post) do
    Fabricate(:post, topic:, user: lookalike, raw: "Harmless words from the look-alike user.")
  end

  let(:topic_path) { "/t/#{topic.slug}/#{topic.id}" }

  def quoting_post(raw)
    Fabricate(:post, topic:, user: friend, raw:)
  end

  def post_selector(post)
    "#post_#{post.post_number}"
  end

  before { ignore! }

  context "when the member has opted in" do
    before do
      enable_for_everyone!
      sign_in(viewer)
    end

    it "hides only the attributed quote and keeps the surrounding writing" do
      post = quoting_post(<<~RAW)
        Friend prose before the quote.

        [quote="quinn, post:#{ignored_post.post_number}, topic:#{topic.id}"]
        Quoted secret words.
        [/quote]

        Friend prose between the quotes.

        [quote="quinn2, post:#{lookalike_post.post_number}, topic:#{topic.id}"]
        Quoted harmless words.
        [/quote]

        [quote="QUINN"]
        Shouted secret words.
        [/quote]

        Friend prose after the quotes.
      RAW

      visit(topic_path)

      within(post_selector(post)) do
        expect(page).to have_content("Friend prose before the quote.")
        expect(page).to have_content("Friend prose between the quotes.")
        expect(page).to have_content("Friend prose after the quotes.")
        expect(page).to have_content("Quoted harmless words.")
        expect(page).to have_css("aside.quote[data-username='quinn2'] .title", text: "quinn2")

        expect(page).to have_no_content("Quoted secret words.")
        expect(page).to have_no_content("Shouted secret words.")
        expect(page).to have_no_css("aside.quote[data-username='quinn']")
        expect(page).to have_no_css("aside.quote[data-username='QUINN']")
        expect(page).to have_css(
          ".enhanced-ignore-placeholder--quote[role='note']",
          text: EnhancedIgnoreHelpers::QUOTE_PLACEHOLDER,
          count: 2,
        )
        # The placeholder must not repeat the ignored person's identity.
        expect(page).to have_no_css(".enhanced-ignore-quote-guard", text: /quinn\b/i)
      end
    end

    it "handles nested quotes without erasing unrelated outer text or duplicating placeholders" do
      inner_ignored = quoting_post(<<~RAW)
        Lead-in text.

        [quote="alice"]
        Outer words by a friend.

        [quote="quinn"]
        Inner secret words.
        [/quote]

        Outer tail by a friend.
        [/quote]
      RAW

      outer_ignored = quoting_post(<<~RAW)
        Second lead-in text.

        [quote="quinn"]
        Outer secret words.

        [quote="quinn"]
        Doubly nested secret words.
        [/quote]

        [quote="alice"]
        Friend words swallowed by the ignored outer quote.
        [/quote]
        [/quote]

        Closing remark.
      RAW

      visit(topic_path)

      within(post_selector(inner_ignored)) do
        expect(page).to have_content("Lead-in text.")
        expect(page).to have_content("Outer words by a friend.")
        expect(page).to have_content("Outer tail by a friend.")
        expect(page).to have_no_content("Inner secret words.")
        expect(page).to have_css(
          ".enhanced-ignore-placeholder--quote",
          text: EnhancedIgnoreHelpers::QUOTE_PLACEHOLDER,
          count: 1,
        )
      end

      within(post_selector(outer_ignored)) do
        expect(page).to have_content("Second lead-in text.")
        expect(page).to have_content("Closing remark.")
        expect(page).to have_no_content("Outer secret words.")
        expect(page).to have_no_content("Doubly nested secret words.")
        # One placeholder for the hidden subtree, not one per nested quote.
        expect(page).to have_css(
          ".enhanced-ignore-placeholder--quote",
          text: EnhancedIgnoreHelpers::QUOTE_PLACEHOLDER,
          count: 1,
        )
      end
    end

    it "leaves unattributed, malformed and unknown markup alone" do
      post = quoting_post(<<~RAW)
        Plain intro.

        [quote]
        Unattributed copy of secret words.
        [/quote]

        > Markdown blockquote mentioning quinn by name.

        [quote="quinn
        Broken quote that never closes properly.

        [quote="someone-who-does-not-exist, post:999, topic:#{topic.id}"]
        Words attributed to an unknown account.
        [/quote]

        Talking about quinn and @quinn in ordinary prose stays visible.
      RAW

      visit(topic_path)

      within(post_selector(post)) do
        expect(page).to have_content("Unattributed copy of secret words.")
        expect(page).to have_content("Markdown blockquote mentioning quinn by name.")
        expect(page).to have_content("Broken quote that never closes properly.")
        expect(page).to have_content("Words attributed to an unknown account.")
        expect(page).to have_content(
          "Talking about quinn and @quinn in ordinary prose stays visible.",
        )
        expect(page).to have_no_css(
          ".enhanced-ignore-placeholder--quote",
          text: EnhancedIgnoreHelpers::QUOTE_PLACEHOLDER,
        )
      end
    end

    it "does not reveal an ignored author's post when a mis-attributed quote is expanded" do
      post = quoting_post(<<~RAW)
        Intro to a quote with a forged attribution.

        [quote="quinn2, post:#{ignored_post.post_number}, topic:#{topic.id}"]
        Original secret
        [/quote]

        Outro.
      RAW

      visit(topic_path)

      within(post_selector(post)) do
        # Attribution is all the client can see, so the excerpt itself stays.
        expect(page).to have_css("aside.quote[data-username='quinn2']", text: "Original secret")

        find("aside.quote[data-username='quinn2'] .quote-toggle").click

        expect(page).to have_css(".expanded-quote", visible: :all)
        expect(page).to have_css(".expanded-quote .enhanced-ignore-cooked", visible: :hidden)
        expect(page).to have_no_content("words from the ignored user")
        expect(page).to have_content("Outro.")
      end
    end

    it "keeps working for posts added by a live update and after an edit" do
      visit(topic_path)
      expect(page).to have_css(post_selector(first_post))

      live = nil
      using_session(:author) do
        live =
          PostCreator.create!(
            friend,
            topic_id: topic.id,
            raw: "Live prose.\n\n[quote=\"quinn\"]\nLive secret words.\n[/quote]\n\nLive tail.",
          )
      end

      within(post_selector(live)) do
        expect(page).to have_content("Live prose.")
        expect(page).to have_content("Live tail.")
        expect(page).to have_no_content("Live secret words.")
        expect(page).to have_css(
          ".enhanced-ignore-placeholder--quote",
          text: EnhancedIgnoreHelpers::QUOTE_PLACEHOLDER,
          count: 1,
        )
      end

      PostRevisor.new(live).revise!(
        friend,
        raw:
          "Edited prose.\n\n[quote=\"quinn\"]\nEdited secret words.\n[/quote]\n\n[quote=\"quinn2\"]\nEdited harmless words.\n[/quote]",
      )

      within(post_selector(live)) do
        expect(page).to have_content("Edited prose.")
        expect(page).to have_content("Edited harmless words.")
        expect(page).to have_no_content("Edited secret words.")
        expect(page).to have_css(
          ".enhanced-ignore-placeholder--quote",
          text: EnhancedIgnoreHelpers::QUOTE_PLACEHOLDER,
          count: 1,
        )
      end
    end

    it "covers posts loaded while scrolling through a long topic" do
      40.times do |index|
        Fabricate(:post, topic:, user: friend, raw: "Filler reply number #{index}.")
      end
      far =
        quoting_post("Far prose.\n\n[quote=\"quinn\"]\nFar secret words.\n[/quote]\n\nFar tail.")

      visit(topic_path)
      expect(page).to have_no_css(post_selector(far))

      visit("#{topic_path}/#{far.post_number}")

      within(post_selector(far)) do
        expect(page).to have_content("Far prose.")
        expect(page).to have_content("Far tail.")
        expect(page).to have_no_content("Far secret words.")
        expect(page).to have_css(
          ".enhanced-ignore-placeholder--quote",
          text: EnhancedIgnoreHelpers::QUOTE_PLACEHOLDER,
          count: 1,
        )
      end
    end
  end

  context "when the member has not opted in" do
    before { sign_in(viewer) }

    it "adds nothing to the page" do
      post = quoting_post("Prose.\n\n[quote=\"quinn\"]\nUntouched words.\n[/quote]")

      visit(topic_path)

      within(post_selector(post)) do
        expect(page).to have_content("Untouched words.")
        expect(page).to have_css("aside.quote[data-username='quinn']")
        expect(page).to have_no_css(".enhanced-ignore-quote-guard", visible: :all)
      end
    end
  end
end
