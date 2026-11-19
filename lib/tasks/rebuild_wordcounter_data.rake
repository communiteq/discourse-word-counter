# frozen_string_literal: true

desc "Count words for all posts"
task "wordcounter:count_post_words" => :environment do
  puts "Removing all existing counter fields"
  PostCustomField.where(name: DiscourseWordCounter::WORD_COUNT_FIELD).delete_all
  UserCustomField.where(name: DiscourseWordCounter::WORD_COUNT_FIELD).delete_all

  puts "Calculating word counts for all posts"
  posts = Post.joins(:topic).where(topics: { archetype: Archetype.default })
  post_count = posts.count

  posts
    .find_each
    .with_index(1) do |post, index|
      puts "Processing post #{index} of #{post_count}" if index == 1 || (index % 100).zero?
      DiscourseWordCounter::WordCounter.process_post(post)
    end

  puts "Done."
end

desc "Destroy badges"
task "wordcounter:destroy_badges" => :environment do
  badge_grouping = BadgeGrouping.find_by(name: DiscourseWordCounter::BADGE_GROUP_NAME)
  badge_grouping&.badges&.destroy_all
  badge_grouping&.destroy!
  puts "Badges and badge group have been removed."
end

desc "Create badges"
task "wordcounter:create_badges" => :environment do
  badge_grouping =
    BadgeGrouping.find_or_create_by!(name: DiscourseWordCounter::BADGE_GROUP_NAME) do |grouping|
      grouping.position = BadgeGrouping.maximum(:position).to_i + 1
    end

  badge_configs = [
    {
      name: "Contributor",
      lower_bound: 251,
      upper_bound: 1000,
      period: :total,
      image: "Contributor",
    },
    { name: "Patron", lower_bound: 1001, upper_bound: 2500, period: :total, image: "Patron" },
    {
      name: "Sr. Member",
      lower_bound: 2501,
      upper_bound: 10_000,
      period: :total,
      image: "Sr-Member",
    },
    {
      name: "Influencer",
      lower_bound: 10_000,
      upper_bound: 9_999_999_999,
      period: :total,
      image: "Influencer",
    },
    {
      name: "Legend",
      lower_bound: 10_000,
      upper_bound: 9_999_999_999,
      period: :last_year,
      image: "Legendary",
    },
  ]

  badge_configs.each do |config|
    badge = Badge.find_or_initialize_by(name: config[:name])
    badge.assign_attributes(
      badge_type_id: BadgeType::Gold,
      allow_title: true,
      auto_revoke: true,
      badge_grouping_id: badge_grouping.id,
      trigger: Badge::Trigger::None,
      image: "/plugins/discourse-word-counter/images/Discourse-Icons-#{config[:image]}.svg",
      query:
        if config[:period] == :last_year
          <<~SQL
            SELECT u.id AS user_id, MAX(p.created_at) AS granted_at
            FROM posts p
            LEFT JOIN post_custom_fields ucf ON ucf.post_id = p.id
            LEFT JOIN users u ON u.id = p.user_id
            WHERE ucf.name = '#{DiscourseWordCounter::WORD_COUNT_FIELD}'
              AND p.created_at > NOW() - INTERVAL '1 YEAR'
            GROUP BY u.id
            HAVING SUM(ucf.value::integer) BETWEEN #{config[:lower_bound]} AND #{config[:upper_bound]}
          SQL
        else
          <<~SQL
            SELECT u.id AS user_id, NOW() AS granted_at
            FROM users u
            LEFT JOIN user_custom_fields ucf ON ucf.user_id = u.id
            WHERE ucf.name = '#{DiscourseWordCounter::WORD_COUNT_FIELD}'
              AND u.id NOT IN (
                SELECT u.id AS user_id
                FROM posts p
                LEFT JOIN post_custom_fields pcf ON pcf.post_id = p.id
                LEFT JOIN users u ON u.id = p.user_id
                WHERE pcf.name = '#{DiscourseWordCounter::WORD_COUNT_FIELD}'
                  AND p.created_at > NOW() - INTERVAL '1 YEAR'
                GROUP BY u.id
                HAVING SUM(pcf.value::integer) >= 10000
              )
            GROUP BY u.id
            HAVING SUM(ucf.value::integer) BETWEEN #{config[:lower_bound]} AND #{config[:upper_bound]}
          SQL
        end,
    )
    badge.save!
  end

  Jobs::BadgeGrant.run
  puts "Badges and badge group have been created."
end
