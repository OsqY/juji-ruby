require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  test "requires a strictly positive amount" do
    user = users(:one)

    [ 0, -1 ].each do |amount|
      transaction = user.transactions.new(
        amount: amount,
        category: "food",
        description: "Invalid amount",
        transaction_type: :expense,
        date: Date.current
      )

      assert_not transaction.valid?
      assert transaction.errors[:amount].any?
    end
  end
end
