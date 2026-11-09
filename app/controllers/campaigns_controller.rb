class CampaignsController < ApplicationController
  def show
    @campaign = find_campaign
    if @campaign.nil?
      render :missing, status: :not_found
      return
    end

    @donation = @campaign.donations.build
    @page = @campaign.donation_page
  end

  private
    def find_campaign
      params[:id].present? ? Campaign.find(params[:id]) : Campaign.featured
    end
end
