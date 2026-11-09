class DonationsController < ApplicationController
  before_action :set_campaign

  def index
    unless turbo_frame_request?
      redirect_to campaign_path(@campaign)
      return
    end

    @page = @campaign.donation_page(params[:before])
    render layout: false
  end

  def create
    @donation = @campaign.donations.build(donation_params)

    if @donation.save
      @donation.publish
      redirect_to campaign_path(@campaign), notice: thank_you_notice
    else
      @page = @campaign.donation_page(1)
      render "campaigns/show", status: :unprocessable_entity
    end
  end

  private
    def set_campaign
      @campaign = Campaign.find(params[:campaign_id])
    end

    def donation_params
      params.require(:donation).permit(:donor_name, :donor_email, :amount, :note)
    end

    def thank_you_notice
      "Thank you, #{@donation.donor_name}. Your gift of #{helpers.money(@donation.amount_cents)} is recorded."
    end
end
