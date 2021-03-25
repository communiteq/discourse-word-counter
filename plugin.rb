# name: discourse-word-counter
# about: Discourse Word Counter plugin
# version: 1.0
# authors: richard@communiteq.com
# url: https://www.communiteq.com/

require_relative "lib/word_counter"

after_initialize do
  register_post_custom_field_type('word_count', :integer)
  add_to_serializer(:post, :word_count, false) { object.custom_fields['word_count'] || 0 }
  add_to_serializer(:post, :user_word_count, false) { object.user.custom_fields['word_count'] || 0 }

  register_user_custom_field_type('word_count', :integer)
  add_to_serializer(:user, :word_count, false) { object.custom_fields['word_count'] || 0 }

  DiscourseEvent.on(:before_post_process_cooked) do |doc, post|
    ::WordCounter.process_post(post)
  end

  add_to_serializer(:user, :badges) do
    badges = []

    object.badges.each do |b|
      b.icon.gsub! "fa-", ""
      badges.push(b)
    end

    ActiveModel::ArraySerializer.new(
      badges,
      each_serializer: BadgeSerializer
    ).as_json
  end

  add_to_serializer(:post, :word_counter_badges) do
    ActiveModel::ArraySerializer.new(object&.user&.word_counter_badges, each_serializer: BadgeSerializer).as_json
  end

  add_to_serializer(:post, :include_word_counter_badges?) do
    object&.user&.word_counter_badges.present?
  end

  add_to_class(:user, :word_counter_badges) do
    featured_badges =  BadgeGrouping.where(name: 'Contribution').first&.badges&.pluck(:id) || []
    badges.select { |b| featured_badges.include?(b.id) }
  end

end
