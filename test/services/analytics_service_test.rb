require "test_helper"

class AnalyticsServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "analytics@test.com", password: "password123", password_confirmation: "password123")
  end

  # Spending by Month Tests
  test "spending_by_month returns data for specified months" do
    today = Time.zone.today
    Transaction.create!(user_id: @user.id, description: "Test", category: "Food", amount: 50.00, date: today, transaction_type: "expense")
    Transaction.create!(user_id: @user.id, description: "Test2", category: "Food", amount: 30.00, date: today - 1.month, transaction_type: "expense")
    
    data = AnalyticsService.spending_by_month(@user, months: 12)
    
    assert data.is_a?(Hash)
    assert data.size > 0
    assert data.values.all? { |v| v.is_a?(Numeric) }
  end

  # Spending by Category Tests
  test "spending_by_category returns top categories" do
    Transaction.create!(user_id: @user.id, description: "Food", category: "Food", amount: 100.00, date: Time.zone.today, transaction_type: "expense")
    Transaction.create!(user_id: @user.id, description: "Transport", category: "Transport", amount: 50.00, date: Time.zone.today, transaction_type: "expense")
    Transaction.create!(user_id: @user.id, description: "Food2", category: "Food", amount: 25.00, date: Time.zone.today, transaction_type: "expense")
    
    data = AnalyticsService.spending_by_category(@user, limit: 5)
    
    assert data.is_a?(Hash)
    assert data.size <= 5
    assert data.keys.first == "food"
  end

  test "spending_by_category returns limited results" do
    5.times do |i|
      Transaction.create!(user_id: @user.id, description: "Test#{i}", category: "Category#{i}", amount: (i + 1) * 10.0, date: Time.zone.today, transaction_type: "expense")
    end
    
    data = AnalyticsService.spending_by_category(@user, limit: 3)
    
    assert data.size == 3
  end

  # Habit Completion Rate Tests
  test "habit_completion_rate calculates percentage" do
    habit = Habit.create!(user_id: @user.id, name: "Exercise")
    HabitLog.create!(habit_id: habit.id, completed: true, log_date: Time.zone.today)
    HabitLog.create!(habit_id: habit.id, completed: false, log_date: 1.day.ago.to_date)
    
    data = AnalyticsService.habit_completion_rate(@user, months: 1)
    
    assert data.is_a?(Hash)
    assert data.size > 0
    assert data.values.all? { |v| v.between?(0, 100) }
  end

  # Project Status Tests
  test "project_status returns count by status" do
    Project.create!(user_id: @user.id, name: "Active", description: "Test", target_date: Time.zone.today + 30.days)
    Project.create!(user_id: @user.id, name: "Overdue", description: "Test", target_date: Time.zone.today - 5.days)
    
    data = AnalyticsService.project_status(@user)
    
    assert data.is_a?(Hash)
    assert data.key?(:active)
    assert data.key?(:overdue)
  end

  # Alerts Trend Tests
  test "alerts_trend returns notification counts per month" do
    Notification.create!(user_id: @user.id, notification_type: "budget_exceeded", message: "Test alert")
    Notification.create!(user_id: @user.id, notification_type: "budget_exceeded", message: "Test alert 2")
    
    data = AnalyticsService.alerts_trend(@user, months: 12)
    
    assert data.is_a?(Hash)
    assert data.size > 0
    assert data.values.all? { |v| v.is_a?(Integer) }
  end

  # Weekly Balance Tests
  test "weekly_balance calculates balance per week" do
    today = Time.zone.today
    Transaction.create!(user_id: @user.id, description: "Income", category: "Salary", amount: 1000.00, date: today, transaction_type: "income")
    Transaction.create!(user_id: @user.id, description: "Expense", category: "Food", amount: 50.00, date: today, transaction_type: "expense")
    
    data = AnalyticsService.weekly_balance(@user, weeks: 12)
    
    assert data.is_a?(Hash)
    assert data.size > 0
    assert data.values.all? { |v| v.is_a?(Numeric) }
  end

  # Project Progress Tests
  test "project_progress returns progress for each project" do
    project = Project.create!(user_id: @user.id, name: "Test", description: "Test", target_date: Time.zone.today + 30.days)
    ProjectTask.create!(project_id: project.id, name: "Task 1", completed: true)
    ProjectTask.create!(project_id: project.id, name: "Task 2", completed: false)
    
    data = AnalyticsService.project_progress(@user)
    
    assert data.is_a?(Array)
    assert data.any?
    assert data.first.key?(:progress)
    assert data.first[:progress] == 50.0
  end

  # Expense Summary Tests
  test "expense_summary returns total and by category" do
    Transaction.create!(user_id: @user.id, description: "Food", category: "Food", amount: 100.00, date: Time.zone.today, transaction_type: "expense")
    Transaction.create!(user_id: @user.id, description: "Transport", category: "Transport", amount: 50.00, date: Time.zone.today, transaction_type: "expense")
    Transaction.create!(user_id: @user.id, description: "Income", category: "Salary", amount: 1000.00, date: Time.zone.today, transaction_type: "income")
    
    data = AnalyticsService.expense_summary(@user, days: 30)
    
    assert data.is_a?(Hash)
    assert data[:total] == 150.0
    assert data[:by_category].key?("food")
    assert data[:by_category]["food"] == 100.0
  end

  # User Isolation Tests
  test "analytics respects user boundaries" do
    other_user = User.create!(email_address: "other@test.com", password: "password123", password_confirmation: "password123")
    
    Transaction.create!(user_id: @user.id, description: "User1", category: "Food", amount: 100.00, date: Time.zone.today, transaction_type: "expense")
    Transaction.create!(user_id: other_user.id, description: "User2", category: "Food", amount: 200.00, date: Time.zone.today, transaction_type: "expense")
    
    user1_summary = AnalyticsService.expense_summary(@user, days: 30)
    user2_summary = AnalyticsService.expense_summary(other_user, days: 30)
    
    assert user1_summary[:total] == 100.0
    assert user2_summary[:total] == 200.0
  end

  # Edge Cases
  test "spending_by_month with no transactions returns zero values" do
    data = AnalyticsService.spending_by_month(@user, months: 12)
    
    assert data.is_a?(Hash)
    assert data.values.all? { |v| v.zero? }
  end

  test "habit_completion_rate with no habits returns zero" do
    data = AnalyticsService.habit_completion_rate(@user, months: 12)
    
    assert data.is_a?(Hash)
    assert data.values.all? { |v| v.zero? }
  end

  test "project_progress with no projects returns empty array" do
    data = AnalyticsService.project_progress(@user)
    
    assert data.is_a?(Array)
    assert data.empty?
  end
end
