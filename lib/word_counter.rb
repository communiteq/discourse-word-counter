# frozen_string_literal: true

module DiscourseWordCounter
  WORD_COUNT_FIELD = "word_count"
  BADGE_GROUP_NAME = "Contribution"

  class WordCounter
    QUOTE_PATTERN = %r{\[quote.*?\](.*?)\[/quote\]}im

    def self.count(raw)
      raw.to_s.gsub(QUOTE_PATTERN, "").split.size
    end

    def self.process_post(post)
      return if post.archetype != Archetype.default || post.user.blank?

      old_count = post.custom_fields[WORD_COUNT_FIELD].to_i
      new_count = count(post.raw)
      return if old_count == new_count

      user = post.user

      Post.transaction do
        post.custom_fields[WORD_COUNT_FIELD] = new_count
        post.save_custom_fields(true)

        user.with_lock do
          user_count = user.custom_fields.fetch(WORD_COUNT_FIELD, old_count).to_i
          user.custom_fields[WORD_COUNT_FIELD] = user_count - old_count + new_count
          user.save_custom_fields(true)
        end
      end
    end
  end
end
