require "test_helper"

class ExpenseSplitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    sign_in_as(@user)
  end

  test "renders the inline spreadsheet with saved-name autocomplete" do
    @user.people.create!(name: "Ana")

    get expense_splits_path

    assert_response :success
    assert_select "form[action='#{expense_splits_path}']"
    assert_select "label[for='split_amount']", text: "Total pagado por ti (L)"
    assert_includes response.body, "pagada por ti en lempiras"
    assert_select "datalist#expense-split-people option[value='Ana']"
    assert_select "[data-controller='expense-split']"
  end

  test "creates a split and reuses or creates people atomically" do
    existing = @user.people.create!(name: "Ana")

    assert_difference "Transaction.count", 1 do
      assert_difference "ExpenseShare.count", 2 do
        assert_difference "Person.count", 1 do
          post expense_splits_path, params: {
            split: {
              description: "Dinner", total_amount: "30.00", date: Date.current,
              shares: {
                "0" => { person_name: " ana ", amount: "10" },
                "1" => { person_name: "Luis", amount: "20" }
              }
            }
          }
          assert_response :redirect
        end
      end
    end

    assert_redirected_to expense_splits_path
    transaction = @user.transactions.order(:created_at).last
    assert_equal "food", transaction.category
    assert_equal [ existing.id, @user.people.find_by(normalized_name: "luis").id ], transaction.expense_shares.order(:amount).pluck(:person_id)
  end

  test "rejects over-allocation without persisting transaction or new person" do
    assert_no_difference [ "Transaction.count", "ExpenseShare.count", "Person.count" ] do
      post expense_splits_path, params: {
        split: {
          description: "Dinner", total_amount: "10", date: Date.current,
          shares: { "0" => { person_name: "New Person", amount: "11" } }
        }
      }
    end

    assert_response :unprocessable_entity
    assert_equal 0, @user.people.where(normalized_name: "new person").count
  end

  test "rejects sub-cent amounts before database rounding" do
    assert_no_difference [ "Transaction.count", "ExpenseShare.count", "Person.count" ] do
      post expense_splits_path, params: {
        split: {
          description: "Tiny split", amount: "0.01", date: Date.current,
          shares: {
            "0" => { person_name: "Ana", amount: "0.005" },
            "1" => { person_name: "Luis", amount: "0.005" }
          }
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match "máximo dos decimales", response.body
  end

  test "rejects non-finite money without persisting records" do
    assert_no_difference [ "Transaction.count", "ExpenseShare.count", "Person.count" ] do
      post expense_splits_path, params: {
        split: {
          description: "Invalid money", amount: "NaN", date: Date.current,
          shares: { "0" => { person_name: "Ana", amount: "1.00" } }
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "normalizes names per account and prevents cross-account toggles" do
    person = @user.people.create!(name: "  Bob ")
    assert_equal "Bob", person.name
    assert_raises(ActiveRecord::RecordNotUnique) { @user.people.create!(name: "bOB") }

    transaction = @other_user.transactions.create!(amount: 5, description: "Other", category: "food", transaction_type: :expense, date: Date.current)
    share = transaction.expense_shares.create!(person: @other_user.people.create!(name: "Other"), amount: 5)
    patch toggle_expense_share_path(share)
    assert_response :not_found
  end

  test "toggles settlement for current user's share" do
    transaction = @user.transactions.create!(amount: 5, description: "Snack", category: "food", transaction_type: :expense, date: Date.current)
    share = transaction.expense_shares.create!(person: @user.people.create!(name: "Sam"), amount: 5)

    patch toggle_expense_share_path(share)
    assert_response :redirect
    assert share.reload.settled_at.present?

    patch toggle_expense_share_path(share)
    assert_nil share.reload.settled_at
  end
end
