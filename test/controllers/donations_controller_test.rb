require "test_helper"

class DonationsControllerTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  setup do
    @campaign = campaigns(:oak_street)
  end

  test "recording a gift queues the thank you" do
    assert_enqueued_emails 1 do
      post campaign_donations_path(@campaign), params: {
        donation: { donor_name: "Casey Nguyen", donor_email: "casey@example.com", amount: "100" }
      }
    end

    assert_redirected_to campaign_path(@campaign)
    follow_redirect!
    assert_match "Your gift of $100.00 is recorded.", response.body
  end

  test "an invalid gift is neither recorded nor published" do
    assert_no_enqueued_jobs do
      post campaign_donations_path(@campaign), params: {
        donation: { donor_name: "Casey Nguyen", donor_email: "casey@example.com", amount: "0.50" }
      }
    end

    assert_response :unprocessable_content
    assert_select ".form-errors li", "Amount must be between $1 and $100,000"
  end

  test "a frame request loads gifts older than the cursor" do
    12.times do |index|
      @campaign.donations.create!(
        donor_name: format("Donor %02d", index),
        donor_email: "donor#{index}@example.com",
        amount: "20",
        created_at: index.minutes.ago
      )
    end
    cursor = @campaign.donations.page.last

    get campaign_donations_path(@campaign, before: cursor), headers: { "Turbo-Frame" => dom_id(cursor, :after) }

    assert_response :success
    assert_select "turbo-frame##{dom_id(cursor, :after)}"
    assert_match "Donor 10", response.body
    assert_match "Donor 11", response.body
    assert_no_match "Donor 00", response.body
  end

  test "a visit outside a frame returns to the campaign" do
    get campaign_donations_path(@campaign, before: 1)

    assert_redirected_to campaign_path(@campaign)
  end
end
