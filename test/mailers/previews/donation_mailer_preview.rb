class DonationMailerPreview < ActionMailer::Preview
  def thank_you
    DonationMailer.thank_you(Donation.recent.first || sample_donation)
  end

  private
    def sample_donation
      campaign = Campaign.new(
        title: "Classroom libraries for Oak Street",
        goal_cents: 1_200_000,
        ends_on: Date.new(2027, 5, 15)
      )
      donation = campaign.donations.build(
        donor_name: "Priya Shah",
        donor_email: "priya.shah@example.com",
        amount_cents: 10_000
      )
      donation.note = "For the kindergarten shelf."
      donation
    end
end
