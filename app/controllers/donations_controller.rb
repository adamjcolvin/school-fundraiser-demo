class DonationsController < ApplicationController
  before_action :set_campaign

  # The next page of gifts, as a lazy Turbo Frame. A visit outside a frame
  # goes back to the campaign.
  def index
    return redirect_to campaign_path(@campaign) unless turbo_frame_request?

    @cursor = @campaign.donations.find(params[:before])
    @donations = @campaign.donations.page(after: @cursor)
    render layout: false
  end

  def create
    @donation = @campaign.donations.build(donation_params)

    if @donation.save
      DonationMailer.thank_you(@donation).deliver_later
      redirect_to campaign_path(@campaign), notice: thank_you_notice
    else
      @donations = @campaign.donations.page
      render "campaigns/show", status: :unprocessable_content
    end
  end

  private
    def set_campaign
      @campaign = Campaign.find(params[:campaign_id])
    end

    def donation_params
      params.expect(donation: [ :donor_name, :donor_email, :amount, :note ])
    end

    def thank_you_notice
      t(".thank_you", name: @donation.donor_name, amount: helpers.money(@donation.amount_cents))
    end
end
