require "test_helper"

class DonationMailerTest < ActionMailer::TestCase
  test "thanks the donor by name and amount" do
    campaign = campaigns(:oak_street)
    donation = campaign.donations.create!(
      donor_name: "Casey Nguyen",
      donor_email: "casey@example.com",
      amount: "100",
      note: "<div>Hello <strong>there</strong></div>"
    )

    email = DonationMailer.thank_you(donation)

    assert_equal [ "casey@example.com" ], email.to
    assert_equal [ "gifts@oakstreet.example" ], email.from
    assert_equal "Thank you for your gift to #{campaign.title}", email.subject

    body = email.text_part.body.decoded
    assert_match "Casey Nguyen", body
    assert_match "$100.00", body
    assert_match "$200.00", body
    assert_match "there", body
    assert_match "No card was charged", body
  end
end
