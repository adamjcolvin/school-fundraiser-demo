class DonationMailer < ApplicationMailer
  def thank_you(donation)
    @donation = donation
    @campaign = donation.campaign

    mail to: donation.donor_email, subject: default_i18n_subject(campaign: @campaign.title)
  end
end
