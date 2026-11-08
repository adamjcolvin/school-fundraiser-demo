module DonationsHelper
  # True when the gift is one of the suggested whole-dollar amounts.
  def amount_selected?(donation, dollars)
    donation.amount_cents == dollars * 100
  end
end
