require "test_helper"

class BudgetTest < ActiveSupport::TestCase
  test "normalizes category and month" do
    budget = users(:one).budgets.new(category: "  Food ", month: "2026-08-15", monthly_limit: 100)

    assert budget.valid?
    assert_equal "food", budget.category
    assert_equal Date.new(2026, 8, 1), budget.month
  end

  test "requires a positive monthly limit" do
    budget = users(:one).budgets.new(category: "food", month: Date.current, monthly_limit: 0)

    assert_not budget.valid?
    assert budget.errors[:monthly_limit].any?
  end

  test "allows only one category budget per user and month" do
    user = users(:one)
    month = Date.current
    user.budgets.create!(category: "food", month: month, monthly_limit: 100)
    duplicate = user.budgets.new(category: " FOOD ", month: month.end_of_month, monthly_limit: 200)

    assert_not duplicate.valid?
    assert duplicate.errors[:category].any?
  end
end
