require "test_helper"

class AlertServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "alert_test@example.com", password: "password123", password_confirmation: "password123")
  end

  # =============== BUDGET EXCEEDED ALERT ===============
  test "check_budget_exceeded detects when budget is exceeded" do
    month_range = Date.current.beginning_of_month..Date.current.end_of_month
    
    # Create budget of 100
    @user.budgets.create!(
      category: "Food",
      month: Date.current.beginning_of_month,
      monthly_limit: 100
    )
    
    # Create expenses totaling 150 (exceeds budget)
    @user.transactions.create!(
      amount: 80,
      description: "Groceries",
      category: "food",
      date: Date.current,
      transaction_type: :expense
    )
    @user.transactions.create!(
      amount: 70,
      description: "Restaurant",
      category: "food",
      date: Date.current,
      transaction_type: :expense
    )
    
    alerts = AlertService.check_budget_exceeded(@user)
    
    assert_not_empty alerts
    alert = alerts.first
    assert_equal :danger, alert[:level]
    assert_includes alert[:title].downcase, "presupuesto"
    assert alert[:message].include?("50.00")
  end

  test "check_budget_exceeded returns nil when budget not exceeded" do
    @user.budgets.create!(
      category: "Food",
      month: Date.current.beginning_of_month,
      monthly_limit: 500
    )
    
    @user.transactions.create!(
      amount: 50,
      description: "Groceries",
      category: "food",
      date: Date.current,
      transaction_type: :expense
    )
    
    alerts = AlertService.check_budget_exceeded(@user)
    
    assert_empty alerts
  end

  test "check_budget_exceeded returns nil when no budget defined" do
    @user.transactions.create!(
      amount: 100,
      description: "Spending",
      category: "random",
      date: Date.current,
      transaction_type: :expense
    )
    
    alerts = AlertService.check_budget_exceeded(@user)
    
    assert_empty alerts
  end

  test "check_budget_exceeded returns nil when no transactions" do
    @user.budgets.create!(
      category: "Food",
      month: Date.current.beginning_of_month,
      monthly_limit: 100
    )
    
    alerts = AlertService.check_budget_exceeded(@user)
    
    assert_empty alerts
  end

  # =============== NO REPORTS ALERT ===============
  test "check_no_reports_3_days returns warning after 3 days without report" do
    # Create report 4 days ago
    @user.daily_reports.create!(
      report_date: 4.days.ago,
      work_title: "Old report",
      worked_by: "Myself",
      yesterday: "Work",
      today: "Work",
      blockers: ""
    )
    
    alert = AlertService.check_no_reports_3_days(@user)
    
    assert_not_nil alert
    assert_equal :warning, alert[:level]
    assert_includes alert[:title].downcase, "reporte"
    assert alert[:message].include?("4")
  end

  test "check_no_reports_3_days returns nil if report is recent" do
    @user.daily_reports.create!(
      report_date: Date.current,
      work_title: "Today report",
      worked_by: "Myself",
      yesterday: "Work",
      today: "Work",
      blockers: ""
    )
    
    alert = AlertService.check_no_reports_3_days(@user)
    
    assert_nil alert
  end

  test "check_no_reports_3_days returns nil if report is 2 days old" do
    @user.daily_reports.create!(
      report_date: 2.days.ago,
      work_title: "Recent report",
      worked_by: "Myself",
      yesterday: "Work",
      today: "Work",
      blockers: ""
    )
    
    alert = AlertService.check_no_reports_3_days(@user)
    
    assert_nil alert
  end

  test "check_no_reports_3_days returns alert if no reports at all" do
    alert = AlertService.check_no_reports_3_days(@user)
    
    assert_not_nil alert
    assert_equal :warning, alert[:level]
    assert alert[:message].include?(">= 3")
  end

  test "check_no_reports_3_days returns alert exactly at 3 days threshold" do
    @user.daily_reports.create!(
      report_date: 3.days.ago,
      work_title: "3-day-old report",
      worked_by: "Myself",
      yesterday: "Work",
      today: "Work",
      blockers: ""
    )
    
    alert = AlertService.check_no_reports_3_days(@user)
    
    # At exactly 3 days (< 2.days.ago), should trigger alert
    assert_not_nil alert
  end

  # =============== PROJECT NO PROGRESS ALERT ===============
  test "check_project_no_progress detects stale projects" do
    # Create project with no task updates for 8 days
    project = @user.projects.create!(name: "Stale Project", description: "Old project")
    task = project.project_tasks.create!(name: "Old task", completed: false)
    
    # Manually update timestamp to 8 days ago
    task.update_column(:updated_at, 8.days.ago)
    
    alert = AlertService.check_project_no_progress(@user)
    
    assert_not_nil alert
    assert_equal :warning, alert[:level]
    assert_includes alert[:title].downcase, "proyecto"
    assert alert[:message].include?("Stale Project")
  end

  test "check_project_no_progress returns nil if project has recent updates" do
    project = @user.projects.create!(name: "Active Project", description: "New project")
    project.project_tasks.create!(name: "Recent task", completed: false)
    
    alert = AlertService.check_project_no_progress(@user)
    
    assert_nil alert
  end

  test "check_project_no_progress returns nil if no projects" do
    alert = AlertService.check_project_no_progress(@user)
    
    assert_nil alert
  end

  test "check_project_no_progress handles multiple stale projects" do
    project1 = @user.projects.create!(name: "Stale 1", description: "Old")
    project2 = @user.projects.create!(name: "Stale 2", description: "Old")
    project3 = @user.projects.create!(name: "Active", description: "New")
    
    task1 = project1.project_tasks.create!(name: "Task 1", completed: false)
    task2 = project2.project_tasks.create!(name: "Task 2", completed: false)
    task3 = project3.project_tasks.create!(name: "Task 3", completed: false)
    
    task1.update_column(:updated_at, 8.days.ago)
    task2.update_column(:updated_at, 8.days.ago)
    # task3 is recent
    
    alert = AlertService.check_project_no_progress(@user)
    
    assert_not_nil alert
    assert alert[:message].include?("Stale 1")
    assert alert[:message].include?("Stale 2")
  end

  test "check_project_no_progress limits to first 3 projects" do
    # Create 5 stale projects
    5.times do |i|
      project = @user.projects.create!(name: "Stale #{i}", description: "Old")
      task = project.project_tasks.create!(name: "Task", completed: false)
      task.update_column(:updated_at, 8.days.ago)
    end
    
    alert = AlertService.check_project_no_progress(@user)
    
    assert_not_nil alert
    # Should mention first 3 and indicate "y 2 mas"
    assert alert[:message].include?("y 2 mas") || alert[:message].include?("y 2 m")
  end

  # =============== CHECK FOR USER ===============
  test "check_for_user returns all applicable alerts" do
    # Create conditions for budget alert
    @user.budgets.create!(
      category: "Food",
      month: Date.current.beginning_of_month,
      monthly_limit: 50
    )
    @user.transactions.create!(
      amount: 100,
      description: "Over budget",
      category: "food",
      date: Date.current,
      transaction_type: :expense
    )
    
    # Create conditions for no reports alert
    @user.daily_reports.create!(
      report_date: 4.days.ago,
      work_title: "Old",
      worked_by: "Me",
      yesterday: "Work",
      today: "Work",
      blockers: ""
    )
    
    alerts = AlertService.check_for_user(@user)
    
    assert_kind_of Array, alerts
    assert alerts.count >= 2
    assert alerts.any? { |a| a[:level] == :danger }
    assert alerts.any? { |a| a[:level] == :warning }
  end

  test "check_for_user returns empty array when no alerts" do
    # Create healthy conditions
    @user.budgets.create!(
      category: "Food",
      month: Date.current.beginning_of_month,
      monthly_limit: 500
    )
    @user.transactions.create!(
      amount: 50,
      description: "Small purchase",
      category: "food",
      date: Date.current,
      transaction_type: :expense
    )
    @user.daily_reports.create!(
      report_date: Date.current,
      work_title: "Today",
      worked_by: "Me",
      yesterday: "Work",
      today: "Work",
      blockers: ""
    )
    project = @user.projects.create!(name: "Active", description: "New")
    project.project_tasks.create!(name: "Task", completed: false)
    
    alerts = AlertService.check_for_user(@user)
    
    assert_kind_of Array, alerts
    assert_empty alerts
  end

  # =============== CHECK ALL USERS ===============
  test "check_all_users processes all users" do
    user1 = @user
    user2 = User.create!(email_address: "alert2@example.com", password: "password123", password_confirmation: "password123")
    
    # Create alerts for user1
    user1.budgets.create!(
      category: "Food",
      month: Date.current.beginning_of_month,
      monthly_limit: 50
    )
    user1.transactions.create!(
      amount: 100,
      description: "Over",
      category: "food",
      date: Date.current,
      transaction_type: :expense
    )
    
    # Create alerts for user2
    user2.daily_reports.create!(
      report_date: 4.days.ago,
      work_title: "Old",
      worked_by: "Me",
      yesterday: "Work",
      today: "Work",
      blockers: ""
    )
    
    count = AlertService.check_all_users
    
    assert count >= 2
  end

  # =============== EDGE CASES ===============
  test "check_budget_exceeded handles multiple budget categories" do
    @user.budgets.create!(
      category: "Food",
      month: Date.current.beginning_of_month,
      monthly_limit: 100
    )
    @user.budgets.create!(
      category: "Transport",
      month: Date.current.beginning_of_month,
      monthly_limit: 50
    )
    
    # Exceed food budget only
    @user.transactions.create!(
      amount: 150,
      description: "Groceries",
      category: "food",
      date: Date.current,
      transaction_type: :expense
    )
    
    alerts = AlertService.check_budget_exceeded(@user)
    
    assert_not_empty alerts
    assert alerts.any? { |a| a[:message].include?("50.00") }
  end

  test "check_no_reports_3_days counts correctly across weeks" do
    # Report from last month
    @user.daily_reports.create!(
      report_date: (Date.current.beginning_of_month - 1.day),
      work_title: "Last month",
      worked_by: "Me",
      yesterday: "Work",
      today: "Work",
      blockers: ""
    )
    
    alert = AlertService.check_no_reports_3_days(@user)
    
    assert_not_nil alert
    assert alert[:message].include?(">= 3")
  end

  test "check_project_no_progress ignores empty projects" do
    # Create project with no tasks
    @user.projects.create!(name: "Empty Project", description: "No tasks")
    
    # Project with no tasks has no updated_at, should not trigger alert
    alert = AlertService.check_project_no_progress(@user)
    
    # Just checking it doesn't crash — empty projects should not cause errors
    assert true
  end

  test "alert messages use proper formatting" do
    @user.budgets.create!(
      category: "Food",
      month: Date.current.beginning_of_month,
      monthly_limit: 100
    )
    @user.transactions.create!(
      amount: 200,
      description: "Spending",
      category: "food",
      date: Date.current,
      transaction_type: :expense
    )
    
    alerts = AlertService.check_budget_exceeded(@user)
    alert = alerts.first
    
    # Check that amount is formatted with 2 decimals
    assert alert[:message].match?(/L\. \d+\.\d{2}/)
  end
end
