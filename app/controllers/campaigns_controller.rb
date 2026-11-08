class CampaignsController < ApplicationController
  def show
    @campaign = params[:id].present? ? Campaign.find(params[:id]) : Campaign.current

    if @campaign.nil?
      render :missing, status: :not_found
      return
    end

    @donation = @campaign.donations.build
    @page = @campaign.donation_page(1)
  end
end
