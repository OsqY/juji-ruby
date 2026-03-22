require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)

    @transaction = @user.transactions.create!(
      amount: 120.50,
      description: "Pago de prueba",
      transaction_type: :expense,
      category: "general",
      date: Date.current
    )
  end

  test "should get index" do
    get transactions_path
    assert_response :success
  end

  test "should get new" do
    get new_transaction_path
    assert_response :success
  end

  test "should get show" do
    get transaction_path(@transaction)
    assert_response :success
    assert_match "DETALLE", response.body
  end

  test "should destroy transaction" do
    assert_difference("Transaction.count", -1) do
      delete transaction_path(@transaction, month: Date.current.strftime("%Y-%m"))
    end

    assert_redirected_to transactions_path(month: Date.current.strftime("%Y-%m"))
  end
end
