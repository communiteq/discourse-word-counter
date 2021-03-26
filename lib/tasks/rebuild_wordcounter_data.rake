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
    i = i + 1
    t.posts.each do |p|
      ::WordCounter.process_post(p)
    end
  end
  puts "Done."
end

desc "Destroy badges"
task "wordcounter:destroy_badges" => :environment do
    BadgeGrouping.where(name: 'Contribution')&.first&.badges&.destroy_all
    BadgeGrouping.where(name: 'Contribution')&.first&.delete
    puts "Badges and badgegroup have been removed."
end

desc "Create badges"
task "wordcounter:create_badges" => :environment do
    badge_grouping = BadgeGrouping.find_or_create_by(name: 'Contribution') do |bg|
      bg.position = BadgeGrouping.maximum(:position)+1
    end

    badges = [
      {
         'name': 'Contributor',
         'lowerbound': 251,
         'upperbound': 1000,
         'period': 'total',
         'image': 'Contributor'
      },
      {
        'name': 'Patron',
        'lowerbound': 1001,
        'upperbound': 2500,
        'period': 'total',
        'image': 'Patron'
      },
      {
        'name': 'Sr. Member',
        'lowerbound': 2501,
        'upperbound': 10000,
        'period': 'total',
        'image': 'Sr-Member'
      },
      {
        'name': 'Influencer',
        'lowerbound': 10000,
        'upperbound': 9999999999,
        'period': 'total',
        'image': 'Influencer'
      },
      {
        'name': 'Legend',
        'lowerbound': 10000,
        'upperbound': 9999999999,
        'period': 'lastyear',
        'image': 'Legendary'
      }
    ]

    badges.each do |cfg|
      Badge.find_or_create_by(name: cfg[:name]) do |badge|
        badge.badge_type_id = 1
        badge.allow_title = true
        if cfg[:period] == 'lastyear'
            badge.query = %{
                SELECT u.id AS user_id, MAX(p.created_at) as granted_at
                FROM posts p
                LEFT JOIN post_custom_fields ucf ON ucf.post_id = p.id
                LEFT JOIN users u ON u.id = p.user_id
                WHERE ucf.name = 'word_count'
                AND p.created_at > NOW() - INTERVAL '1 YEAR'
                GROUP BY u.id
                HAVING SUM(ucf.value::integer) BETWEEN #{cfg[:lowerbound]} AND  #{cfg[:upperbound]}
            }
        else
            badge.query = %{
                SELECT u.id AS user_id, NOW() as granted_at
                FROM users u
                LEFT JOIN user_custom_fields ucf ON ucf.user_id = u.id
                WHERE ucf.name = 'word_count'
                AND u.id NOT IN (
                    SELECT u.id AS user_id
                    FROM posts p
                    LEFT JOIN post_custom_fields ucf ON ucf.post_id = p.id
                    LEFT JOIN users u ON u.id = p.user_id
                    WHERE ucf.name = 'word_count'
                      AND p.created_at > NOW() - INTERVAL '1 YEAR'
                    GROUP BY u.id
                    HAVING SUM(ucf.value::integer) >= 10000
                )
                GROUP BY u.id
                HAVING SUM(ucf.value::integer) BETWEEN #{cfg[:lowerbound]} AND  #{cfg[:upperbound]}
            }
        end
        badge.auto_revoke = true
        badge.badge_grouping_id = badge_grouping.id
        badge.trigger = 0
        badge.image = "/plugins/discourse-word-counter/images/Discourse-Icons-#{cfg[:image]}.svg"
      end
    end
    Jobs::BadgeGrant.run
    puts "Badges and badgegroup have been created."
end
