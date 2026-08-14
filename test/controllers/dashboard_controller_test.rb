require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other = users(:two)
  end

  test "authenticated user sees dashboard metrics" do
    @user.daily_reports.create!(
      report_date: Date.current,
      work_title: "Dashboard report",
      worked_by: "Tester",
      yesterday: "Previous work",
      today: "Current work",
      blockers: "Open blocker"
    )
    habit = @user.habits.create!(name: "Exercise")
    habit.habit_logs.create!(log_date: Date.current, completed: true)
    project = @user.projects.create!(name: "Dashboard project")
    project.project_tasks.create!(name: "Completed task", completed: true)
    @user.transactions.create!(
      amount: 100,
      description: "Salary",
      transaction_type: :income,
      category: "work",
      date: Date.current
    )
    @user.transactions.create!(
      amount: 30,
      description: "Lunch",
      transaction_type: :expense,
      category: "food",
      date: Date.current
    )
    @user.budgets.create!(
      category: "food",
      month: Date.current.beginning_of_month,
      monthly_limit: 100
    )

    sign_in_as(@user)
    get dashboard_path

    assert_response :success
    assert_match(/Dashboard report/, response.body)
    assert_match(/L\. 70\.00/, response.body)
    assert_match(/L\. 100\.00/, response.body)
    assert_match(/L\. 30\.00/, response.body)
  end

  test "dashboard does not expose another user's data" do
    @other.daily_reports.create!(
      report_date: Date.current,
      work_title: "PRIVATE OTHER REPORT",
      worked_by: "Other",
      yesterday: "Private yesterday",
      today: "Private today",
      blockers: "Private blocker"
    )
    @other.transactions.create!(
      amount: 999.99,
      description: "Private transaction",
      transaction_type: :expense,
      category: "private",
      date: Date.current
    )

    sign_in_as(@user)
    get dashboard_path

    assert_response :success
    assert_no_match(/PRIVATE OTHER REPORT|999\.99/, response.body)
  end
end
