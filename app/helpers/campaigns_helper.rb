module CampaignsHelper
  def campaign_timing(campaign)
    days = campaign.days_left

    if days.negative?
      t("campaigns.timing.ended", count: days.abs)
    elsif days.zero?
      t("campaigns.timing.today")
    else
      t("campaigns.timing.remaining", count: days)
    end
  end
end
