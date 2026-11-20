# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe Rake::Task do
  before do
    if Rake::Task.task_defined?("wordcounter:create_badges")
      Rake::Task["wordcounter:create_badges"].clear
    end
    load File.expand_path("../../lib/tasks/rebuild_wordcounter_data.rake", __dir__)
    Jobs::BadgeGrant.stubs(:run)
  end

  def run_task
    task = Rake::Task["wordcounter:create_badges"]
    task.reenable
    silence_stdout { task.invoke }
  end

  it "creates badges with uploaded images and can be run again without replacing them" do
    original_images = Dir[File.expand_path("../../public/images/*.svg", __dir__)]
    original_hashes = original_images.to_h { |path| [path, Digest::SHA256.file(path).hexdigest] }
    run_task

    grouping = BadgeGrouping.find_by!(name: "Contribution")
    badges = grouping.badges.order(:name).to_a
    expect(badges.map(&:name)).to contain_exactly(
      "Contributor",
      "Patron",
      "Sr. Member",
      "Influencer",
      "Legend",
    )
    expect(badges).to all(have_attributes(image_upload_id: be_present))
    expect(badges.map { |badge| badge.image_upload.url }).to all(be_present)
    expect(badges.map { |badge| badge.image_upload.extension }).to all(eq("svg"))
    expect(original_images.to_h { |path| [path, Digest::SHA256.file(path).hexdigest] }).to eq(
      original_hashes,
    )

    # A site may have customized a badge image between runs.
    badges.first.update!(image_upload: badges.last.image_upload)
    image_ids = badges.map(&:image_upload_id)

    run_task

    expect(grouping.badges.order(:name).pluck(:image_upload_id)).to eq(image_ids)
    expect(grouping.badges.count).to eq(5)
  end

  it "ignores posts without users and excludes only users who qualify for Legend" do
    eligible = Fabricate(:user)
    recent_legend = Fabricate(:user)
    old_legend = Fabricate(:user)
    [eligible, recent_legend, old_legend].each do |user|
      UserCustomField.create!(user: user, name: "word_count", value: "500")
    end

    orphan = Fabricate(:post)
    orphan.update_columns(user_id: nil)
    PostCustomField.create!(post: orphan, name: "word_count", value: "10000")

    recent_post = Fabricate(:post, user: recent_legend)
    PostCustomField.create!(post: recent_post, name: "word_count", value: "10000")
    old_post = Fabricate(:post, user: old_legend, created_at: 2.years.ago)
    PostCustomField.create!(post: old_post, name: "word_count", value: "10000")

    badge_users =
      {
        "Patron" => 1500,
        "Sr. Member" => 5000,
        "Influencer" => 15_000,
      }.transform_values do |word_count|
        user = Fabricate(:user)
        UserCustomField.create!(user: user, name: "word_count", value: word_count.to_s)
        user
      end

    run_task

    contributor = Badge.find_by!(name: "Contributor")
    users = ActiveRecord::Base.connection.select_values(contributor.query).map(&:to_i)
    expect(users).to include(eligible.id, old_legend.id)
    expect(users).not_to include(recent_legend.id)

    badge_users.each do |name, user|
      users = ActiveRecord::Base.connection.select_values(Badge.find_by!(name: name).query)
      expect(users).to include(user.id)
    end

    legend = Badge.find_by!(name: "Legend")
    legend_users = ActiveRecord::Base.connection.select_values(legend.query)
    expect(legend_users).to include(recent_legend.id)
    expect(legend_users).not_to include(nil, eligible.id, old_legend.id)

    contributor.update_column(:query, "SELECT NULL AS user_id, NOW() AS granted_at")
    run_task
    users = ActiveRecord::Base.connection.select_values(contributor.reload.query).map(&:to_i)
    expect(users).to include(eligible.id, old_legend.id)
    expect(users).not_to include(recent_legend.id)
  end
end
