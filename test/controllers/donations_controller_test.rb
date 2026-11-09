require "test_helper"

class DonationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:oak_street)
  end

  test "recording a gift publishes it" do
    assert_enqueued_emails 1 do
      post campaign_donations_path(@campaign), params: {
        donation: {
          donor_name: "Casey Nguyen",
          donor_email: "casey@example.com",
          amount: "100"
        }
      }
    end

    assert_redirected_to campaign_path(@campaign)
    follow_redirect!
    assert_match "Your gift of $100.00 is recorded.", response.body
  end

  test "an invalid gift is not published" do
    assert_no_enqueued_emails do
      post campaign_donations_path(@campaign), params: {
        donation: {
          donor_name: "Casey Nguyen",
          donor_email: "casey@example.com",
          amount: "0.50"
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
