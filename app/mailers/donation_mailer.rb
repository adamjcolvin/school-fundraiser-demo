class DonationMailer < ApplicationMailer
  def thank_you(donation)
    @donation = donation
    @campaign = donation.campaign

    mail(
      to: donation.donor_email,
      subject: "Thank you for your gift to #{@campaign.title}"
    )
  end
end
