# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe Rake::Task do
  before do
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
end
