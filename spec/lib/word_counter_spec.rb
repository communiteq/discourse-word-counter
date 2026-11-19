# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseWordCounter::WordCounter do
  fab!(:user)
  fab!(:post) { Fabricate(:post, user: user) }

  before do
    PostCustomField.where(name: DiscourseWordCounter::WORD_COUNT_FIELD).delete_all
    UserCustomField.where(name: DiscourseWordCounter::WORD_COUNT_FIELD).delete_all
    post.reload
    user.reload
  end

  describe ".count" do
    it "counts whitespace-separated words and excludes quoted content" do
      raw = "one two\n[quote=Alice]three four[/quote]\nfive"

      expect(described_class.count(raw)).to eq(3)
    end

    it "handles an empty value" do
      expect(described_class.count(nil)).to eq(0)
    end
  end

  describe ".process_post" do
    it "stores the post count and adjusts the user's total when the post changes" do
      post.update_column(:raw, "one two three")
      described_class.process_post(post.reload)

      expect(post.reload.custom_fields[DiscourseWordCounter::WORD_COUNT_FIELD]).to eq(3)
      expect(user.reload.custom_fields[DiscourseWordCounter::WORD_COUNT_FIELD]).to eq(3)

      post.update_column(:raw, "one two three four five")
      described_class.process_post(post.reload)

      expect(post.reload.custom_fields[DiscourseWordCounter::WORD_COUNT_FIELD]).to eq(5)
      expect(user.reload.custom_fields[DiscourseWordCounter::WORD_COUNT_FIELD]).to eq(5)
    end

    it "does not count private messages" do
      private_message_post = Fabricate(:private_message_post, user: user, raw: "one two three")

      described_class.process_post(private_message_post)

      expect(
        private_message_post.reload.custom_fields[DiscourseWordCounter::WORD_COUNT_FIELD],
      ).to be_nil
      expect(user.reload.custom_fields[DiscourseWordCounter::WORD_COUNT_FIELD]).to be_nil
    end
  end
end
