require "test_helper"

class AuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @user_a = users(:one)
    @user_b = users(:two)
    sign_in_as(@user_a)
  end

  # ============= TRANSACTIONS =============
  test "user cannot view another user's transaction" do
    other_transaction = @user_b.transactions.create!(
      amount: 100,
      description: "Other user's transaction",
      category: "food",
      date: Date.current,
      transaction_type: :expense
    )
    
    get transaction_path(other_transaction)
    assert_response :not_found
  end

  test "user cannot destroy another user's transaction" do
    other_transaction = @user_b.transactions.create!(
      amount: 100,
      description: "Other user's transaction",
      category: "food",
      date: Date.current,
      transaction_type: :expense
    )
    
    assert_no_difference("Transaction.count") do
      delete transaction_path(other_transaction, month: Date.current.strftime("%Y-%m"))
    end
    assert_response :not_found
  end

  # ============= DAILY REPORTS =============
  test "user cannot view another user's daily report" do
    other_report = @user_b.daily_reports.create!(
      report_date: Date.current,
      work_title: "Other report",
      worked_by: "Other",
      yesterday: "Work",
      today: "Work",
      blockers: ""
    )
    
    get daily_report_path(other_report)
    assert_response :not_found
  end

  test "user cannot edit another user's daily report" do
    other_report = @user_b.daily_reports.create!(
      report_date: Date.current,
      work_title: "Other report",
      worked_by: "Other",
      yesterday: "Work",
      today: "Work",
      blockers: ""
    )
    
    get edit_daily_report_path(other_report)
    assert_response :not_found
  end

  test "user cannot update another user's daily report" do
    other_report = @user_b.daily_reports.create!(
      report_date: Date.current,
      work_title: "Other report",
      worked_by: "Other",
      yesterday: "Work",
      today: "Work",
      blockers: ""
    )
    
    patch daily_report_path(other_report), params: {
      daily_report: { work_title: "Hacked" }
    }
    assert_response :not_found
  end

  test "user cannot destroy another user's daily report" do
    other_report = @user_b.daily_reports.create!(
      report_date: Date.current,
      work_title: "Other report",
      worked_by: "Other",
      yesterday: "Work",
      today: "Work",
      blockers: ""
    )
    
    assert_no_difference("DailyReport.count") do
      delete daily_report_path(other_report)
    end
    assert_response :not_found
  end

  test "user cannot toggle blocker on another user's daily report" do
    other_report = @user_b.daily_reports.create!(
      report_date: Date.current,
      work_title: "Other report",
      worked_by: "Other",
      yesterday: "Work",
      today: "Work",
      blockers: "Blocker"
    )
    
    patch toggle_blocker_daily_report_path(other_report), params: { resolved: true }
    assert_response :not_found
  end

  # ============= PROJECTS =============
  test "user cannot destroy another user's project" do
    other_project = @user_b.projects.create!(name: "Other project", description: "Test")
    
    assert_no_difference("Project.count") do
      delete project_path(other_project)
    end
    assert_response :not_found
  end

  # ============= HABITS =============
  test "user cannot toggle another user's habit" do
    other_habit = @user_b.habits.create!(name: "Other habit")
    
    post toggle_habit_path(other_habit), params: { date: Date.current }
    assert_response :not_found
  end

  test "user cannot destroy another user's habit" do
    other_habit = @user_b.habits.create!(name: "Other habit")
    
    assert_no_difference("Habit.count") do
      delete habit_path(other_habit)
    end
    assert_response :not_found
  end

  # ============= BUDGETS =============
  test "user cannot destroy another user's budget" do
    other_budget = @user_b.budgets.create!(
      category: "Food",
      month: Date.current.beginning_of_month,
      monthly_limit: 100
    )
    
    assert_no_difference("Budget.count") do
      delete budget_path(other_budget)
    end
    assert_response :not_found
  end

  # ============= SHOPPING ITEMS =============
  test "user cannot destroy another user's shopping item" do
    other_item = @user_b.shopping_items.create!(name: "Other item", quantity: "1")
    
    assert_no_difference("ShoppingItem.count") do
      delete shopping_item_path(other_item)
    end
    assert_response :not_found
  end

  # ============= WHITEBOARDS =============
  test "user cannot view another user's private whiteboard" do
    other_whiteboard = @user_b.whiteboards.create!(name: "Private whiteboard")
    
    get whiteboard_path(other_whiteboard)
    assert_redirected_to whiteboards_path
    assert_equal "No tienes acceso a esta pizarra.", flash[:alert]
  end

  test "user cannot destroy another user's whiteboard" do
    other_whiteboard = @user_b.whiteboards.create!(name: "Private whiteboard")
    
    assert_no_difference("Whiteboard.count") do
      delete whiteboard_path(other_whiteboard)
    end
    assert_redirected_to whiteboards_path
  end

  # ============= ANONYMOUS FORMS =============
  test "user cannot destroy another user's anonymous form" do
    other_form = @user_b.anonymous_forms.new(
      title: "Other form",
      description: "Test",
      response_limit: 10
    )
    other_form.questions.build(
      prompt: "Question 1",
      question_type: :free_text,
      position: 1
    )
    other_form.save!
    
    assert_no_difference("AnonymousForm.count") do
      delete anonymous_form_path(other_form)
    end
    assert_response :not_found
  end

  # ============= NOTIFICATIONS =============
  test "user cannot mark another user's notification as read" do
    other_notification = @user_b.notifications.create!(
      notification_type: :budget_exceeded,
      message: "Test"
    )
    
    patch mark_as_read_notification_path(other_notification)
    assert_response :not_found
  end

  # ============= SEARCH =============
  test "user cannot search in another user's data" do
    @user_b.transactions.create!(
      amount: 999,
      description: "Secret transaction",
      category: "secret",
      date: Date.current,
      transaction_type: :expense
    )
    
    get search_path, params: { q: "Secret" }
    assert_response :success
    assert_no_match(/Secret transaction/, response.body)
  end

  # ============= EXPORTS =============
  test "user cannot export another user's data" do
    @user_b.transactions.create!(
      amount: 999,
      description: "Secret",
      category: "secret",
      date: Date.current,
      transaction_type: :expense
    )
    
    post exports_path, params: { model: "transactions", format: "csv" }
    assert_response :success
    assert_no_match(/Secret/, response.body)
  end
end
