require "test_helper"

class CampaignsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:oak_street)
  end

  test "the root shows the featured campaign with the default gift" do
    get root_path

    assert_response :success
    assert_select "h1", @campaign.title
    assert_select "form[action=?]", campaign_donations_path(@campaign)
    assert_select "input[name='donation[amount]'][value='50']"
  end

  test "a campaign is shown by id" do
    get campaign_path(@campaign)

    assert_response :success
    assert_select "h1", @campaign.title
  end

  test "an unknown campaign is not found" do
    get campaign_path(@campaign.id + 1)

    assert_response :not_found
  end

  test "explains how to seed when there is no campaign" do
    Campaign.destroy_all

    get root_path

    assert_response :not_found
    assert_select "code", "bin/rails db:seed"
  end
end
