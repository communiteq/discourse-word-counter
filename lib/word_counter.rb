class WordCounter
  def self.process_post(post)
    if post.archetype == 'regular'
      old_cnt = post.custom_fields['word_count'] || 0
      cnt = post.raw.gsub(/\[quote.*?\](.*?)\[\/quote\]/im, '').split.count

      if old_cnt != cnt
        post.custom_fields['word_count'] = cnt
        post.save_custom_fields(true)

        old_user_cnt = (post.user.custom_fields['word_count'] || old_cnt) - old_cnt
        post.user.custom_fields['word_count'] = old_user_cnt + cnt
        post.user.save_custom_fields(true)
      end
    end
  end
end
