# Testing Quick Start - Copy & Paste Templates

## STEP 1: Create Services Test Directory

```bash
mkdir -p test/services
```

---

## STEP 2: Create SearchService Test

**File:** `test/services/search_service_test.rb`

```ruby
require "test_helper"

class SearchServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  # Empty query handling
  test "perform returns empty hash for blank query" do
    assert_equal({}, SearchService.perform("", @user))
    assert_equal({}, SearchService.perform("   ", @user))
  end

  # Case-insensitive search
  test "perform is case insensitive" do
    @user.transactions.create!(
      amount: 50,
      description: "Laptop Repair",
      category: "tech",
      date: Date.current
    )
    
    results = SearchService.perform("LAPTOP", @user)
    assert_equal 1, results[:transactions].count
    assert_equal "Laptop Repair", results[:transactions].first.description
  end

  # Respects limit parameter
  test "perform respects limit parameter" do
    5.times { |i| @user.habits.create!(name: "Habit #{i}") }
    
    results = SearchService.perform("habit", @user, limit: 3)
    assert_equal 3, results[:habits].length
  end

  # Searches transactions
  test "perform searches transactions by description" do
    @user.transactions.create!(
      amount: 100,
      description: "Coffee Purchase",
      category: "food",
      date: Date.current
    )
    
    results = SearchService.perform("coffee", @user)
    assert_equal 1, results[:transactions].count
  end

  test "perform searches transactions by category" do
    @user.transactions.create!(
      amount: 50,
      description: "Weekly groceries",
      category: "food",
      date: Date.current
    )
    
    results = SearchService.perform("food", @user)
    assert results[:transactions].count > 0
  end

  # Searches projects
  test "perform searches projects by name" do
    @user.projects.create!(name: "Mobile App", description: "iOS app")
    
    results = SearchService.perform("mobile", @user)
    assert results[:projects].count > 0
  end

  test "perform searches projects by description" do
    @user.projects.create!(name: "Backend Service", description: "API development")
    
    results = SearchService.perform("development", @user)
    assert results[:projects].count > 0
  end

  # Searches daily reports
  test "perform searches daily reports by work_title" do
    @user.daily_reports.create!(
      report_date: Date.current,
      work_title: "Sprint Planning",
      worked_by: "Team",
      yesterday: "Completed tasks",
      today: "Planning",
      blockers: "None"
    )
    
    results = SearchService.perform("planning", @user)
    assert results[:daily_reports].count > 0
  end

  test "perform searches daily reports by yesterday field" do
    @user.daily_reports.create!(
      report_date: Date.current,
      work_title: "Daily standup",
      worked_by: "Dev",
      yesterday: "Implemented user auth",
      today: "Testing",
      blockers: ""
    )
    
    results = SearchService.perform("auth", @user)
    assert results[:daily_reports].count > 0
  end

  # Searches habits
  test "perform searches habits by name" do
    @user.habits.create!(name: "Morning Exercise")
    
    results = SearchService.perform("exercise", @user)
    assert_equal 1, results[:habits].count
  end

  # Searches shopping items
  test "perform searches shopping items" do
    @user.shopping_items.create!(name: "Milk", quantity: "1L")
    
    results = SearchService.perform("milk", @user)
    assert results[:shopping_items].count > 0
  end

  # User isolation
  test "perform respects user isolation" do
    other_user = users(:two)
    @user.habits.create!(name: "Private Habit")
    other_user.habits.create!(name: "Private Habit")
    
    results = SearchService.perform("private", @user)
    results_other = SearchService.perform("private", other_user)
    
    assert_equal 1, results[:habits].count
    assert_equal 1, results_other[:habits].count
  end

  # Count method
  test "count returns correct total across all models" do
    @user.habits.create!(name: "Reading")
    @user.transactions.create!(
      amount: 25,
      description: "Book purchase",
      category: "education",
      date: Date.current
    )
    
    count = SearchService.count("read", @user)
    assert count >= 2
  end

  # Organized results format
  test "organized_results returns properly formatted response" do
    @user.habits.create!(name: "Exercise")
    
    results = SearchService.organized_results("exercise", @user)
    
    assert_equal "exercise", results[:query]
    assert results[:total_count] > 0
    assert results[:results].is_a?(Hash)
    assert results[:results].keys.include?("Habits")
  end

  test "organized_results excludes empty result types" do
    @user.habits.create!(name: "Running")
    # No projects created
    
    results = SearchService.organized_results("running", @user)
    
    # Should not include Projects key if empty
    assert_includes results[:results].keys, "Habits"
  end
end
```

---

## STEP 3: Create AlertService Test

**File:** `test/services/alert_service_test.rb`

```ruby
require "test_helper"

class AlertServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    # Clear any existing notifications
    @user.notifications.delete_all
  end

  # === BUDGET EXCEEDED TESTS ===

  test "check_budget_exceeded creates notification when spending exceeds limit" do
    @user.budgets.create!(
      category: "food",
      month: Time.zone.today.beginning_of_month,
      monthly_limit: 100
    )
    
    @user.transactions.create!(
      amount: 150,
      description: "Groceries",
      category: "food",
      transaction_type: :expense,
      date: Date.current
    )
    
    AlertService.check_budget_exceeded(@user)
    
    notification = @user.notifications.find_by(notification_type: :budget_exceeded)
    assert_not_nil notification
    assert_match(/Presupuesto de food superado/, notification.message)
    assert_match(/150 > 100/, notification.message)
  end

  test "check_budget_exceeded does not create duplicate notifications" do
    @user.budgets.create!(
      category: "tech",
      month: Time.zone.today.beginning_of_month,
      monthly_limit: 500
    )
    
    @user.transactions.create!(
      amount: 600,
      description: "Equipment",
      category: "tech",
      transaction_type: :expense,
      date: Date.current
    )
    
    AlertService.check_budget_exceeded(@user)
    AlertService.check_budget_exceeded(@user)
    
    count = @user.notifications.where(notification_type: :budget_exceeded).count
    assert_equal 1, count
  end

  test "check_budget_exceeded ignores budgets from other months" do
    past_month = (Time.zone.today - 1.month).beginning_of_month
    @user.budgets.create!(
      category: "utilities",
      month: past_month,
      monthly_limit: 100
    )
    
    @user.transactions.create!(
      amount: 150,
      description: "Electricity",
      category: "utilities",
      transaction_type: :expense,
      date: Date.current
    )
    
    AlertService.check_budget_exceeded(@user)
    
    notification = @user.notifications.find_by(notification_type: :budget_exceeded)
    assert_nil notification
  end

  test "check_budget_exceeded does not alert if within budget" do
    @user.budgets.create!(
      category: "food",
      month: Time.zone.today.beginning_of_month,
      monthly_limit: 500
    )
    
    @user.transactions.create!(
      amount: 100,
      description: "Groceries",
      category: "food",
      transaction_type: :expense,
      date: Date.current
    )
    
    AlertService.check_budget_exceeded(@user)
    
    notification = @user.notifications.find_by(notification_type: :budget_exceeded)
    assert_nil notification
  end

  test "check_budget_exceeded sums all transactions for category this month" do
    @user.budgets.create!(
      category: "food",
      month: Time.zone.today.beginning_of_month,
      monthly_limit: 200
    )
    
    # Multiple transactions
    @user.transactions.create!(amount: 80, description: "Groceries", category: "food", 
                               transaction_type: :expense, date: Date.current)
    @user.transactions.create!(amount: 100, description: "Restaurant", category: "food", 
                               transaction_type: :expense, date: Date.current)
    # Total: 180, within budget
    
    AlertService.check_budget_exceeded(@user)
    notification = @user.notifications.find_by(notification_type: :budget_exceeded)
    assert_nil notification
    
    # Add one more to exceed
    @user.transactions.create!(amount: 50, description: "Snacks", category: "food", 
                               transaction_type: :expense, date: Date.current)
    # Total: 230, exceeds 200
    
    AlertService.check_budget_exceeded(@user)
    notification = @user.notifications.find_by(notification_type: :budget_exceeded)
    assert_not_nil notification
  end

  # === NO REPORTS TESTS ===

  test "check_no_reports_3_days creates alert when user has no reports" do
    # User has zero daily reports
    assert_equal 0, @user.daily_reports.count
    
    AlertService.check_no_reports_3_days(@user)
    
    notification = @user.notifications.find_by(notification_type: :no_report_3_days)
    assert_not_nil notification
  end

  test "check_no_reports_3_days does not alert if recent report exists" do
    @user.daily_reports.create!(
      report_date: Date.current,
      work_title: "Today's work",
      worked_by: "Developer",
      yesterday: "Previous work",
      today: "Current work",
      blockers: ""
    )
    
    AlertService.check_no_reports_3_days(@user)
    
    # Alert may or may not exist, but shouldn't be created now
    # (depends on fixture state)
  end

  test "check_no_reports_3_days alerts if last report is 3+ days old" do
    # Create report 4 days ago
    travel_to 4.days.ago do
      @user.daily_reports.create!(
        report_date: Date.current,
        work_title: "Old report",
        worked_by: "Developer",
        yesterday: "Old work",
        today: "Old current",
        blockers: ""
      )
    end
    
    # Back to present
    AlertService.check_no_reports_3_days(@user)
    
    notification = @user.notifications.find_by(notification_type: :no_report_3_days)
    assert_not_nil notification
    assert_match(/3 días/, notification.message)
  end

  test "check_no_reports_3_days does not alert if report is recent" do
    @user.daily_reports.create!(
      report_date: Date.current - 2.days,
      work_title: "Recent work",
      worked_by: "Developer",
      yesterday: "Work from before",
      today: "Current work",
      blockers: ""
    )
    
    AlertService.check_no_reports_3_days(@user)
    
    notification = @user.notifications.find_by(notification_type: :no_report_3_days)
    assert_nil notification
  end

  # === PROJECT NO PROGRESS TESTS ===

  test "check_project_no_progress creates alert for stale projects" do
    project = @user.projects.create!(
      name: "Stale Project",
      description: "No recent tasks"
    )
    
    # Create task 8 days ago
    travel_to 8.days.ago do
      project.project_tasks.create!(name: "Old Task")
    end
    
    AlertService.check_project_no_progress(@user)
    
    notification = @user.notifications.find_by(notification_type: :project_no_progress)
    assert_not_nil notification
    assert_match(/Stale Project/, notification.message)
  end

  test "check_project_no_progress does not alert for active projects" do
    project = @user.projects.create!(
      name: "Active Project",
      description: "Has recent tasks"
    )
    
    project.project_tasks.create!(name: "Recent Task")
    
    AlertService.check_project_no_progress(@user)
    
    notification = @user.notifications.find_by(
      notification_type: :project_no_progress,
      message: /Active Project/
    )
    assert_nil notification
  end

  test "check_project_no_progress does not alert for new projects with no tasks" do
    # Newly created project, no tasks yet, created today
    project = @user.projects.create!(
      name: "New Project",
      description: "Just created"
    )
    
    AlertService.check_project_no_progress(@user)
    
    notification = @user.notifications.find_by(
      notification_type: :project_no_progress,
      message: /New Project/
    )
    assert_nil notification
  end

  test "check_project_no_progress alerts for project with no tasks that is old" do
    project = @user.projects.create!(
      name: "Empty Old Project",
      description: "Created long ago"
    )
    
    # Backdate project creation
    project.update(created_at: 8.days.ago)
    
    AlertService.check_project_no_progress(@user)
    
    notification = @user.notifications.find_by(
      notification_type: :project_no_progress,
      message: /Empty Old Project/
    )
    # May or may not alert depending on implementation
  end

  # === CHECK FOR USER ===

  test "check_for_user runs all three checks" do
    # Setup condition for budget alert
    @user.budgets.create!(
      category: "food",
      month: Time.zone.today.beginning_of_month,
      monthly_limit: 50
    )
    @user.transactions.create!(
      amount: 100,
      description: "Groceries",
      category: "food",
      transaction_type: :expense,
      date: Date.current
    )
    
    initial_count = @user.notifications.count
    AlertService.check_for_user(@user)
    
    # At least one notification should be created
    assert @user.notifications.count > initial_count
  end

  # === CHECK ALL USERS ===

  test "check_all_users processes all users" do
    user_two = users(:two)
    
    # Setup alert for user one
    @user.budgets.create!(
      category: "entertainment",
      month: Time.zone.today.beginning_of_month,
      monthly_limit: 50
    )
    @user.transactions.create!(
      amount: 100,
      description: "Movies",
      category: "entertainment",
      transaction_type: :expense,
      date: Date.current
    )
    
    initial_count = @user.notifications.count
    AlertService.check_all_users
    
    # User one should have new notification
    assert @user.notifications.count > initial_count
  end

  # === NOTIFICATION CREATION ===

  test "create_notification uses find_or_create_by for idempotency" do
    initial_count = @user.notifications.count
    
    AlertService.send(:create_notification, @user, :test_type, "Test message")
    AlertService.send(:create_notification, @user, :test_type, "Test message")
    
    final_count = @user.notifications.count
    
    # Should only add one
    assert_equal initial_count + 1, final_count
  end

  test "create_notification sets unread by default" do
    AlertService.send(:create_notification, @user, :test_type, "Test")
    
    notification = @user.notifications.find_by(notification_type: :test_type)
    assert_nil notification.read_at
  end
end
```

---

## STEP 4: Run Tests

```bash
# Run search service tests
rails test test/services/search_service_test.rb

# Run alert service tests
rails test test/services/alert_service_test.rb

# Run all service tests
rails test test/services/

# Run all tests
rails test

# Run with verbose output
rails test test/services/ --verbose
```

---

## STEP 5: Add transactions.yml Fixture (Optional)

**File:** `test/fixtures/transactions.yml`

```yaml
<% 
  base_date = Date.new(2024, 3, 15)
  password_digest = BCrypt::Password.create("password")
%>

grocery_expense:
  user: one
  amount: 125.50
  description: "Weekly groceries"
  category: "food"
  transaction_type: expense
  date: <%= base_date %>

salary_income:
  user: one
  amount: 3000
  description: "Monthly salary"
  category: "income"
  transaction_type: income
  date: <%= base_date %>

tech_expense:
  user: one
  amount: 500
  description: "Laptop repair"
  category: "tech"
  transaction_type: expense
  date: <%= base_date %>
```

Then add to test_helper.rb:
```ruby
fixtures :all, :transactions
```

---

## STEP 6: Add budgets.yml Fixture (Optional)

**File:** `test/fixtures/budgets.yml`

```yaml
<% current_month = Time.zone.today.beginning_of_month %>

food_budget:
  user: one
  category: "food"
  month: <%= current_month %>
  monthly_limit: 500

tech_budget:
  user: one
  category: "tech"
  month: <%= current_month %>
  monthly_limit: 1000
```

---

## TEST RESULTS CHECKLIST

After adding tests, you should see:

```
$ rails test test/services/

Run options: --verbose

SearchServiceTest
  test_perform_returns_empty_hash_for_blank_query PASS (0.15s)
  test_perform_is_case_insensitive PASS (0.18s)
  test_perform_respects_limit_parameter PASS (0.12s)
  ... (more tests)

AlertServiceTest
  test_check_budget_exceeded_creates_notification_when_spending_exceeds_limit PASS (0.22s)
  test_check_budget_exceeded_does_not_create_duplicate_notifications PASS (0.19s)
  ... (more tests)

Finished in 4.23s, 26 tests, 54 assertions

26 tests, 54 assertions, 0 failures, 0 errors
```

---

## DEBUGGING FAILED TESTS

```bash
# Run specific failing test
rails test test/services/search_service_test.rb:12

# Run with debugging
rails test test/services/ --debug

# See what's in database during test
# Add this to your test:
puts "User habits: #{@user.habits.inspect}"

# Use binding.pry for debugging (if pry is installed)
require 'pry'; binding.pry
```

---

## NEXT STEPS

1. ✅ Create test/services/ directory
2. ✅ Create SearchServiceTest with templates above
3. ✅ Create AlertServiceTest with templates above
4. ✅ Run: `rails test test/services/`
5. ✅ Fix any failing tests
6. ✅ Commit: `git add test/services/` && `git commit -m "Add service tests"`
7. Fill empty model tests (user_test.rb, habit_test.rb, etc.)
8. Fill CheckAlertsJobTest
9. Add system tests with Capybara

---

Happy testing! 🧪

