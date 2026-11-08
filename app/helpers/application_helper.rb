module ApplicationHelper
  def money(cents)
    number_to_currency(BigDecimal(cents.to_i) / 100)
  end

  def campaign_timing(campaign)
    days = campaign.days_left

    if days.negative?
      "Ended #{pluralize(days.abs, "day")} ago"
    elsif days.zero?
      "Ends today"
    else
      "#{pluralize(days, "day")} left"
    end
  end
end
