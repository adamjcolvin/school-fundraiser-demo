require "test_helper"

class CampaignTest < ActiveSupport::TestCase
  setup do
    @campaign = campaigns(:oak_street)
  end

  test "raised cents is the sum of gifts" do
    @campaign.donations.create!(gift(amount: "25.50"))
    @campaign.donations.create!(gift(amount: "10", donor_email: "second@example.com"))

    assert_equal 3_550, @campaign.raised_cents
  end

  test "percent funded is an integer share of the goal" do
    @campaign.donations.create!(gift(amount: "50"))

    assert_equal 25, @campaign.percent_funded
    assert_equal 25, @campaign.percent_bar
    assert_not @campaign.goal_reached?
  end

  test "percent bar stops at 100 when gifts pass the goal" do
    @campaign.donations.create!(gift(amount: "250"))

    assert @campaign.goal_reached?
    assert_operator @campaign.percent_funded, :>, 100
    assert_equal 100, @campaign.percent_bar
  end

  test "days left counts to the end date" do
    expected = (Date.new(2027, 5, 15) - Date.current).to_i

    assert_equal expected, @campaign.days_left
    assert_not @campaign.ended?
  end

  test "lede is the first paragraph and the story is the rest" do
    assert_match "Fifteen classrooms", @campaign.lede
    assert_equal 1, @campaign.story_paragraphs.length
  end

  private
    def gift(overrides = {})
      {
        donor_name: "Ada Lovelace",
        donor_email: "ada@example.com",
        amount: "20",
        skip_notifications: true
      }.merge(overrides)
    end
end
