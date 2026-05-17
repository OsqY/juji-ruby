require "test_helper"

class CheckAlertsJobTest < ActiveJob::TestCase
  test "perform calls AlertService.check_all_users" do
    # Create test data to trigger alerts
    user = users(:one)
    user.budgets.create!(
      category: "Food",
      month: Date.current.beginning_of_month,
      monthly_limit: 100
    )
    user.transactions.create!(
      amount: 150,
      description: "Over budget",
      category: "food",
      date: Date.current,
      transaction_type: :expense
    )
    
    result = CheckAlertsJob.perform_now
    assert result >= 1
  end

  test "perform logs start and completion" do
    # Create test data
    user = users(:one)
    user.budgets.create!(
      category: "Food",
      month: Date.current.beginning_of_month,
      monthly_limit: 100
    )
    user.transactions.create!(
      amount: 150,
      description: "Over budget",
      category: "food",
      date: Date.current,
      transaction_type: :expense
    )
    
    logs = []
    original_logger = Rails.logger
    Rails.logger = Logger.new(StringIO.new)
    Rails.logger.define_singleton_method(:info) { |msg| logs << msg }
    
    CheckAlertsJob.perform_now
    
    Rails.logger = original_logger
    
    assert logs.any? { |msg| msg.include?("Starting alert checks") }
    assert logs.any? { |msg| msg.include?("Completed alert checks") }
  end

  test "perform handles zero alerts for specific user" do
    # Clear existing notifications to avoid interference from other users
    Notification.delete_all
    
    user = User.create!(
      email_address: "zero_alerts@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.budgets.create!(
      category: "Food",
      month: Date.current.beginning_of_month,
      monthly_limit: 500
    )
    user.transactions.create!(
      amount: 50,
      description: "Under budget",
      category: "food",
      date: Date.current,
      transaction_type: :expense
    )
    user.daily_reports.create!(
      report_date: Date.current,
      work_title: "Today",
      worked_by: "Me",
      yesterday: "Work",
      today: "Work",
      blockers: ""
    )
    project = user.projects.create!(name: "Active", description: "Test")
    project.project_tasks.create!(name: "Task 1", completed: false)
    
    # Check that this specific user has 0 alerts
    user_alerts = AlertService.check_for_user(user)
    assert_equal 0, user_alerts.count
  end
end
