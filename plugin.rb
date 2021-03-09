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
end
