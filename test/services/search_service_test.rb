require "test_helper"

class SearchServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "search_test@example.com", password: "password123", password_confirmation: "password123")
  end

  # =============== BLANK QUERY HANDLING ===============
  test "perform returns empty hash for blank query" do
    assert_equal({}, SearchService.perform("", @user))
    assert_equal({}, SearchService.perform("   ", @user))
    assert_equal({}, SearchService.perform(nil, @user))
  end

  # =============== CASE-INSENSITIVE SEARCH ===============
  test "perform is case insensitive for transactions" do
    @user.transactions.create!(
      amount: 50,
      description: "Laptop Repair",
      category: "tech",
      date: Date.current,
      transaction_type: :expense
    )
    
    results = SearchService.perform("LAPTOP", @user)
    assert_equal 1, results[:transactions].count
    assert_equal "Laptop Repair", results[:transactions].first.description
  end

  test "perform is case insensitive for projects" do
    @user.projects.create!(name: "Mobile App Development", description: "iOS project")
    
    results = SearchService.perform("MOBILE app", @user)
    assert results[:projects].count > 0
  end

  # =============== LIMIT PARAMETER ===============
  test "perform respects limit parameter" do
    5.times { |i| @user.habits.create!(name: "Habit #{i}") }
    
    results = SearchService.perform("habit", @user, limit: 3)
    assert_equal 3, results[:habits].length
  end

  test "perform default limit is 10" do
    15.times { |i| @user.habits.create!(name: "Habit #{i}") }
    
    results = SearchService.perform("habit", @user)
    assert results[:habits].length <= 10
  end

  # =============== TRANSACTION SEARCHES ===============
  test "perform searches transactions by description" do
    @user.transactions.create!(
      amount: 100,
      description: "Coffee Purchase",
      category: "food",
      date: Date.current,
      transaction_type: :expense
    )
    
    results = SearchService.perform("coffee", @user)
    assert_equal 1, results[:transactions].count
  end

  test "perform searches transactions by category" do
    @user.transactions.create!(
      amount: 50,
      description: "Weekly groceries",
      category: "food",
      date: Date.current,
      transaction_type: :expense
    )
    
    results = SearchService.perform("food", @user)
    assert results[:transactions].count > 0
  end

  test "perform returns partial matches in descriptions" do
    @user.transactions.create!(
      amount: 100,
      description: "Amazon Purchase",
      category: "shopping",
      date: Date.current,
      transaction_type: :expense
    )
    
    results = SearchService.perform("azon", @user)
    assert_equal 1, results[:transactions].count
  end

  # =============== PROJECT SEARCHES ===============
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

  # =============== DAILY REPORT SEARCHES ===============
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

  test "perform searches daily reports by today field" do
    @user.daily_reports.create!(
      report_date: Date.current,
      work_title: "Standup",
      worked_by: "Dev",
      yesterday: "Work",
      today: "Debugging critical issue",
      blockers: ""
    )
    
    results = SearchService.perform("critical", @user)
    assert results[:daily_reports].count > 0
  end

  test "perform searches daily reports by blockers field" do
    @user.daily_reports.create!(
      report_date: Date.current,
      work_title: "Work",
      worked_by: "Dev",
      yesterday: "Tasks",
      today: "Work",
      blockers: "Database connection timeout"
    )
    
    results = SearchService.perform("timeout", @user)
    assert results[:daily_reports].count > 0
  end

  # =============== HABIT SEARCHES ===============
  test "perform searches habits by name" do
    @user.habits.create!(name: "Morning Exercise")
    
    results = SearchService.perform("exercise", @user)
    assert_equal 1, results[:habits].count
  end

  # =============== SHOPPING ITEM SEARCHES ===============
  test "perform searches shopping items by name" do
    @user.shopping_items.create!(name: "Milk", quantity: "1L")
    
    results = SearchService.perform("milk", @user)
    assert results[:shopping_items].count > 0
  end

  test "perform searches shopping items by quantity" do
    @user.shopping_items.create!(name: "Bread", quantity: "2 units")
    
    results = SearchService.perform("units", @user)
    assert results[:shopping_items].count > 0
  end

  # =============== BUDGET SEARCHES ===============
  test "perform searches budgets by category" do
    @user.budgets.create!(
      category: "Food",
      month: Date.current.beginning_of_month,
      monthly_limit: 500
    )
    
    results = SearchService.perform("food", @user)
    assert results[:budgets].count > 0
  end

  # =============== PROJECT TASK SEARCHES ===============
  test "perform searches project tasks by name" do
    project = @user.projects.create!(name: "Project", description: "Test")
    project.project_tasks.create!(name: "Fix login bug", completed: false)
    
    results = SearchService.perform("login", @user)
    assert results[:project_tasks].count > 0
  end

  # =============== SPECIAL CHARACTERS ===============
  test "perform handles special characters in search" do
    @user.transactions.create!(
      amount: 100,
      description: "Pizza (large)",
      category: "food",
      date: Date.current,
      transaction_type: :expense
    )
    
    results = SearchService.perform("large", @user)
    assert results[:transactions].count > 0
  end
  test "perform respects user isolation" do
    other_user = User.create!(email_address: "other@example.com", password: "password123", password_confirmation: "password123")
    
    @user.habits.create!(name: "Private Habit")
    other_user.habits.create!(name: "Private Habit")
    
    results = SearchService.perform("private", @user)
    results_other = SearchService.perform("private", other_user)
    
    assert_equal 1, results[:habits].count
    assert_equal 1, results_other[:habits].count
  end

  test "perform does not return other users' transactions" do
    other_user = User.create!(email_address: "other2@example.com", password: "password123", password_confirmation: "password123")
    
    @user.transactions.create!(
      amount: 100,
      description: "My secret purchase",
      category: "secret",
      date: Date.current,
      transaction_type: :expense
    )
    
    other_user.transactions.create!(
      amount: 50,
      description: "Their secret purchase",
      category: "secret",
      date: Date.current,
      transaction_type: :expense
    )
    
    results = SearchService.perform("secret", @user)
    assert_equal 1, results[:transactions].count
  end

  # =============== COUNT METHOD ===============
  test "count returns correct total across all models" do
    @user.habits.create!(name: "Test Habit")
    @user.transactions.create!(
      amount: 100,
      description: "Test transaction",
      category: "test",
      date: Date.current,
      transaction_type: :expense
    )
    @user.projects.create!(name: "Test project", description: "Test")
    
    total = SearchService.count("test", @user)
    assert total >= 3
  end

  test "count returns 0 for no results" do
    total = SearchService.count("nonexistent_query_xyz", @user)
    assert_equal 0, total
  end

  # =============== ORGANIZED RESULTS ===============
  test "organized_results includes query and total_count" do
    @user.habits.create!(name: "Test Habit")
    
    org_results = SearchService.organized_results("test", @user)
    
    assert_equal "test", org_results[:query]
    assert org_results[:total_count] > 0
    assert org_results[:results].is_a?(Hash)
  end

  test "organized_results excludes empty model results" do
    @user.habits.create!(name: "Test")
    
    org_results = SearchService.organized_results("test", @user)
    
    # Should only include habits, not empty models
    assert_includes org_results[:results].keys, "Habits"
    assert !org_results[:results].keys.include?("Transactions") || org_results[:results]["Transactions"].empty?
  end

  # =============== EMPTY RESULTS ===============
  test "perform returns empty arrays for non-matching query" do
    results = SearchService.perform("completely_nonexistent_xyz", @user)
    
    assert_empty results[:transactions]
    assert_empty results[:habits]
    assert_empty results[:projects]
  end

  # =============== ORDERING ===============
  test "perform orders transactions by date descending" do
    @user.transactions.create!(
      amount: 100,
      description: "First transaction",
      category: "test",
      date: 5.days.ago,
      transaction_type: :expense
    )
    @user.transactions.create!(
      amount: 100,
      description: "Second transaction",
      category: "test",
      date: Date.current,
      transaction_type: :expense
    )
    
    results = SearchService.perform("transaction", @user)
    dates = results[:transactions].map(&:date)
    assert dates == dates.sort.reverse
  end

  test "perform orders projects by created_at descending" do
    p1 = @user.projects.create!(name: "test 1", description: "Test")
    p2 = @user.projects.create!(name: "test 2", description: "Test")
    
    results = SearchService.perform("test", @user)
    assert_equal p2.id, results[:projects].first.id
    assert_equal p1.id, results[:projects].last.id
  end
end
