# frozen_string_literal: true

require "rails_helper"

RSpec.describe PostSerializer do
  fab!(:user)
  fab!(:post) { Fabricate(:post, user: user) }
  fab!(:contribution_grouping) do
    BadgeGrouping.create!(name: DiscourseWordCounter::BADGE_GROUP_NAME, position: 100)
  end
  fab!(:other_grouping) { BadgeGrouping.create!(name: "Other test badges", position: 101) }
  fab!(:contribution_badge) { Fabricate(:badge, badge_grouping: contribution_grouping) }
  fab!(:other_badge) { Fabricate(:badge, badge_grouping: other_grouping) }

  before do
    post.custom_fields[DiscourseWordCounter::WORD_COUNT_FIELD] = 12
    post.save_custom_fields(true)
    user.custom_fields[DiscourseWordCounter::WORD_COUNT_FIELD] = 34
    user.save_custom_fields(true)
    Fabricate(:user_badge, user: user, badge: contribution_badge)
    Fabricate(:user_badge, user: user, badge: other_badge)
  end

  it "includes word counts and only contribution badges" do
    json = described_class.new(post, scope: Guardian.new, root: false).as_json

    expect(json[:word_count]).to eq(12)
    expect(json[:user_word_count]).to eq(34)
    expect(json[:word_counter_badges].map { |badge| badge[:id] }).to contain_exactly(
      contribution_badge.id,
    )
  end
end
