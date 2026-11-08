require "test_helper"

class CampaignsHelperTest < ActionView::TestCase
  setup do
    @campaign = campaigns(:oak_street)
  end

  test "timing for a campaign that is still open" do
    @campaign.ends_on = Date.current + 1
    assert_equal "1 day left", campaign_timing(@campaign)

    @campaign.ends_on = Date.current + 3
    assert_equal "3 days left", campaign_timing(@campaign)
  end

  test "timing for a campaign that ends today" do
    @campaign.ends_on = Date.current

    assert_equal "Ends today", campaign_timing(@campaign)
  end

  test "timing for a campaign that has ended" do
    @campaign.ends_on = Date.current - 1
    assert_equal "Ended 1 day ago", campaign_timing(@campaign)

    @campaign.ends_on = Date.current - 5
    assert_equal "Ended 5 days ago", campaign_timing(@campaign)
  end
end
