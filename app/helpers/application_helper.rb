module ApplicationHelper
  def money(cents)
    number_to_currency(BigDecimal(cents.to_i) / 100)
  end
end
