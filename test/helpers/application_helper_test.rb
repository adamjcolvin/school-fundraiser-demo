require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "money formats cents as dollars" do
    assert_equal "$25.50", money(2_550)
    assert_equal "$1,250.00", money(125_000)
    assert_equal "$0.00", money(nil)
  end
end
