desc "Count words for all posts"
task "wordcounter:count_post_words" => :environment do
  puts "Removing all existing counter fields"
  PostCustomField.where(name: 'word_count').destroy_all
  UserCustomField.where(name: 'word_count').destroy_all

  puts "Calculating word counts for all posts"
  topic_cnt = Topic.where(archetype: 'regular').count
  i = 0
  Topic.where(archetype: 'regular').order(:id).each do |t|
    if ((i % 100) == 0)
      puts "Processing topic #{i+1} of #{topic_cnt}"
    end
    t.posts.each do |p|
      i = i+1
      ::WordCounter.process_post(p)
    end
  end
  puts "Done."
end
