# frozen_string_literal: true

# name: discourse-word-counter
# about: Discourse Word Counter plugin
# version: 4.0
# authors: richard@communiteq.com
# url: https://www.communiteq.com/

require_relative "lib/word_counter"

after_initialize do
  register_post_custom_field_type(DiscourseWordCounter::WORD_COUNT_FIELD, :integer)
  register_user_custom_field_type(DiscourseWordCounter::WORD_COUNT_FIELD, :integer)

  add_to_serializer(:post, :word_count) do
    object.custom_fields[DiscourseWordCounter::WORD_COUNT_FIELD].to_i
  end

  add_to_serializer(:post, :user_word_count) do
    (object.user&.custom_fields&.fetch(DiscourseWordCounter::WORD_COUNT_FIELD, 0) || 0).to_i
  end

  add_to_serializer(:user, :word_count) do
    object.custom_fields[DiscourseWordCounter::WORD_COUNT_FIELD].to_i
  end

  add_to_serializer(:post, :word_counter_badges, include_condition: -> { object.user.present? }) do
    badge_grouping = BadgeGrouping.find_by(name: DiscourseWordCounter::BADGE_GROUP_NAME)
    badges =
      if badge_grouping
        object.user.badges.where(badge_grouping_id: badge_grouping.id)
      else
        Badge.none
      end

    ActiveModel::ArraySerializer.new(badges, each_serializer: BadgeSerializer).as_json
  end

  on(:before_post_process_cooked) do |_doc, post|
    DiscourseWordCounter::WordCounter.process_post(post)
  end
end
