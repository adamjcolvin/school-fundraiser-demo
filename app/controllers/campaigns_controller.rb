class CampaignsController < ApplicationController
  def show
    @campaign = find_campaign
    return render :missing, status: :not_found unless @campaign

    @donation = @campaign.donations.build(amount: Donation::DEFAULT_AMOUNT)
    @donations = @campaign.donations.page
  end

  private
    def find_campaign
      params[:id] ? Campaign.find(params[:id]) : Campaign.featured
    end
end
