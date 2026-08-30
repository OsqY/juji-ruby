require "test_helper"

class ExpenseShareTest < ActiveSupport::TestCase
  test "requires the person and transaction to have the same owner" do
    transaction = users(:one).transactions.create!(
      amount: 10, description: "Lunch", category: "food", transaction_type: :expense, date: Date.current
    )
    share = transaction.expense_shares.new(person: users(:two).people.create!(name: "Other"), amount: 5)

    assert_not share.valid?
    assert share.errors[:person].any?
  end

  test "reports whether the tab is settled" do
    share = ExpenseShare.new

    assert_not share.settled?
    share.settled_at = Time.current
    assert share.settled?
  end

  test "rejects shares attached to income" do
    transaction = users(:one).transactions.create!(
      amount: 10, description: "Refund", category: "food", transaction_type: :income, date: Date.current
    )
    share = transaction.expense_shares.new(person: users(:one).people.create!(name: "Ana"), amount: 5)

    assert_not share.valid?
    assert share.errors[:expense_transaction].any?
  end
end
