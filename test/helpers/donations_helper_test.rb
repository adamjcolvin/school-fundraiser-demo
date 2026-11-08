require "test_helper"

class DonationsHelperTest < ActionView::TestCase
  test "marks the suggested amount that matches the gift" do
    donation = Donation.new(amount: Donation::DEFAULT_AMOUNT)

    assert amount_selected?(donation, 50)
    assert_not amount_selected?(donation, 25)

    donation.amount = "abc"
    assert_not amount_selected?(donation, 50)
  end
end
