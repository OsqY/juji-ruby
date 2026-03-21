# Rails 8.1 Testing Setup Analysis & Guidelines

## QUICK SUMMARY

**Framework:** Minitest (Rails 8.1 default) | **Ruby:** 4.0.1 | **Rails:** 8.1.2

**Test Structure:** 
- 8 controller tests | 8 model tests | 4 integration tests | 1 job test (empty)
- **~1006 total test lines**
- Services: SearchService & AlertService **need tests**

**Key Tools:**
- Capybara + Selenium for browser automation
- Fixtures (YAML) for test data
- Parallel testing enabled
- SessionTestHelper for authentication
- GitHub Actions CI/CD

---

## 1. TESTING FRAMEWORK & SETUP

### Framework: **Minitest** (Rails Default - No RSpec)
- **Why Minitest?** Rails 8.1 includes it by default with zero configuration
- **Test Discovery:** `test/` directory with `*_test.rb` files
- **Test Helper:** `/test/test_helper.rb` (main configuration file)

### Test Dependencies (Gemfile)
```ruby
group :test do
  gem "capybara"          # Browser automation
  gem "selenium-webdriver" # WebDriver for browser testing
end
```

### Versions
- Rails: 8.1.2
- Ruby: 4.0.1
- SQLite3: >=2.1

---

## 2. TEST DIRECTORY STRUCTURE

```
test/
├── test_helper.rb                          # Main config + setup
├── test_helpers/
│   └── session_test_helper.rb             # Auth helper (sign_in_as)
├── controllers/                            # 8 files - ActionDispatch::IntegrationTest
│   ├── sessions_controller_test.rb
│   ├── daily_reports_controller_test.rb
│   ├── notifications_controller_test.rb
│   ├── transactions_controller_test.rb
│   ├── passwords_controller_test.rb
│   ├── public_anonymous_forms_controller_test.rb
│   ├── guides_controller_test.rb
│   └── anonymous_forms_controller_test.rb
├── models/                                 # 8 files - ActiveSupport::TestCase
│   ├── user_test.rb
│   ├── habit_test.rb
│   ├── shopping_item_test.rb
│   ├── daily_report_test.rb
│   ├── habit_log_test.rb
│   ├── project_test.rb
│   ├── project_task_test.rb
│   └── notification_test.rb
├── integration/                            # 4 files - Turbo/Hotwire focused
│   ├── turbo_ux_smoke_test.rb
│   ├── responsive_design_test.rb
│   ├── mobile_interaction_test.rb
│   └── hotwire_native_test.rb
├── jobs/                                   # 1 file - ActiveJob::TestCase
│   └── check_alerts_job_test.rb          # ⚠️ EMPTY
├── fixtures/                               # YAML test data
│   ├── users.yml
│   ├── habits.yml
│   ├── shopping_items.yml
│   ├── daily_reports.yml
│   ├── habit_logs.yml
│   ├── projects.yml
│   ├── project_tasks.yml
│   ├── notifications.yml
│   └── files/
├── helpers/                                # View helper tests (if needed)
├── mailers/                                # Mailer tests (if needed)
└── system/                                 # System/browser tests (empty - use Capybara)
```

**Total Code:** ~1006 lines across all tests

---

## 3. TEST_HELPER.RB CONFIGURATION

### Main Configuration
**File:** `/test/test_helper.rb`

```ruby
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with number_of_processors workers
    parallelize(workers: :number_of_processors)
    
    # Automatically load ALL fixtures from test/fixtures/*.yml
    fixtures :all
    
    # Add custom helper methods available to ALL tests here
  end
end
```

**Key Behaviors:**
- ✅ Parallel testing enabled (faster CI/CD)
- ✅ Automatic fixture loading 
- ✅ SessionTestHelper included for all integration tests
- ✅ Custom assertions available through ActiveSupport::TestCase

### Custom Test Helper
**File:** `/test/test_helpers/session_test_helper.rb`

```ruby
module SessionTestHelper
  def sign_in_as(user)
    # Create session and set signed cookie
    Current.session = user.sessions.create!
    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = Current.session.id
      cookies["session_id"] = cookie_jar[:session_id]
    end
  end

  def sign_out
    # Destroy session and clear cookie
    Current.session&.destroy!
    cookies.delete("session_id")
  end
end

# Include in all integration tests
ActiveSupport.on_load(:action_dispatch_integration_test) do
  include SessionTestHelper
end
```

**Usage:** Available in all `ActionDispatch::IntegrationTest` subclasses

---

## 4. DATABASE CONFIGURATION

**File:** `/config/database.yml`

```yaml
test:
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
  database: storage/test.sqlite3
```

**Setup Commands:**
```bash
rails db:test:prepare   # Create/migrate test database
rails test              # Run all tests
rails test:system       # Run system/browser tests
```

---

## 5. EXISTING TEST PATTERNS

### Pattern 1: Model Tests (ActiveSupport::TestCase)

**File:** `/test/models/user_test.rb`

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end
end
```

**Characteristics:**
- Inherit from `ActiveSupport::TestCase`
- Use `test "description" { }` blocks
- Access fixtures as methods: `users(:one)`
- Focus on model logic, validations, callbacks

**Most model tests are EMPTY (placeholders)**

### Pattern 2: Controller/Integration Tests (ActionDispatch::IntegrationTest)

**File:** `/test/controllers/sessions_controller_test.rb`

```ruby
require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { 
      email_address: @user.email_address, 
      password: "password" 
    }
    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { 
      email_address: @user.email_address, 
      password: "wrong" 
    }
    assert_response :unprocessable_entity
    assert_select "div", /try another email address or password/i
  end

  test "destroy" do
    sign_in_as(User.take)
    delete session_path
    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
```

**Characteristics:**
- Inherit from `ActionDispatch::IntegrationTest`
- Use HTTP verbs: `get`, `post`, `patch`, `put`, `delete`
- Test full request/response cycle
- Use `sign_in_as()` from SessionTestHelper
- Assert responses and DOM content with `assert_select`

### Pattern 3: Turbo Stream Integration Tests

**File:** `/test/integration/turbo_ux_smoke_test.rb`

```ruby
require "test_helper"

class TurboUxSmokeTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
    
    # Create test data inline
    @transaction = @user.transactions.create!(
      amount: 50,
      description: "Compra QA",
      category: "varios",
      date: Date.current
    )
  end

  test "habits create returns turbo replacement" do
    post habits_path,
      params: { habit: { name: "Lectura" } },
      headers: turbo_headers

    assert_response :success
    assert_turbo_replace("habits_content")
    assert_match(/HABIT CREATED/i, @response.body)
  end

  private
    def turbo_headers
      { "Accept" => Mime[:turbo_stream].to_s }
    end

    def assert_turbo_replace(target)
      assert_equal Mime[:turbo_stream].to_s, @response.media_type
      assert_match(%r{<turbo-stream action="replace" target="#{target}">}, @response.body)
    end
end
```

**Characteristics:**
- Mix fixture data with inline record creation
- Custom assertions for Turbo Streams
- Test specific stream action/target
- Private helper methods for reusable logic

### Pattern 4: Job Tests (ActiveJob::TestCase)

**File:** `/test/jobs/check_alerts_job_test.rb`

```ruby
require "test_helper"

class CheckAlertsJobTest < ActiveJob::TestCase
  # CURRENTLY EMPTY - NEEDS TESTS
end
```

**Should test:**
- Job enqueuing
- Job execution
- Job side effects (created records, notifications, etc.)

---

## 6. FIXTURES & TEST DATA

### What Are Fixtures?
- YAML files in `test/fixtures/` directory
- Define test data available to all tests
- Auto-loaded by Rails
- Referenced as methods: `users(:one)`, `habits(:one)`
- Support ERB for dynamic values

### Example Fixture: users.yml

```yaml
<% password_digest = BCrypt::Password.create("password") %>

one:
  email_address: one@example.com
  password_digest: <%= password_digest %>

two:
  email_address: two@example.com
  password_digest: <%= password_digest %>
```

**Usage in Tests:**
```ruby
@user = users(:one)        # Access fixture by label
@all_users = User.all      # Or query normally
```

### Current Fixtures Available
1. `users.yml` - Two test users (email: one@example.com, two@example.com, password: "password")
2. `habits.yml` - Test habits
3. `shopping_items.yml` - Test shopping items
4. `daily_reports.yml` - Test daily reports
5. `habit_logs.yml` - Test habit logs
6. `projects.yml` - Test projects
7. `project_tasks.yml` - Test project tasks
8. `notifications.yml` - Test notifications

### Creating New Fixture Data

```yaml
# test/fixtures/transactions.yml
<% 
  user = users(:one)
  base_date = Date.new(2024, 1, 15)
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
```

---

## 7. CI/CD CONFIGURATION

**File:** `.github/workflows/ci.yml`

### Test Job
```yaml
test:
  runs-on: ubuntu-latest
  steps:
    - name: Checkout code
    - name: Set up Ruby
    - name: Run tests
      env:
        RAILS_ENV: test
      run: bin/rails db:test:prepare test
```

### System Test Job
```yaml
system-test:
  runs-on: ubuntu-latest
  steps:
    - name: Run System Tests
      run: bin/rails db:test:prepare test:system
    - name: Keep screenshots from failed system tests
      uses: actions/upload-artifact@v4
      if: failure()
      with:
        name: screenshots
        path: ${{ github.workspace }}/tmp/screenshots
```

**Full Pipeline:**
1. **scan_ruby** - Brakeman security scan
2. **scan_js** - Importmap audit
3. **lint** - RuboCop code style
4. **test** - Unit & integration tests
5. **system-test** - Browser tests with Capybara

---

## 8. NAMING CONVENTIONS & STRUCTURE

| Type | File Pattern | Class | Location |
|------|--------------|-------|----------|
| Model | `model_test.rb` | `ActiveSupport::TestCase` | `test/models/` |
| Controller | `controller_test.rb` | `ActionDispatch::IntegrationTest` | `test/controllers/` |
| Job | `job_test.rb` | `ActiveJob::TestCase` | `test/jobs/` |
| Integration | `*_test.rb` | `ActionDispatch::IntegrationTest` | `test/integration/` |
| System | `*_test.rb` | `ActionDispatch::SystemTestCase` | `test/system/` |
| Helper | `helper_test.rb` | `ActionView::TestCase` | `test/helpers/` |

---

## 9. KEY ASSERTIONS REFERENCE

```ruby
# Equality & Truthiness
assert(expression)                    # Assert true
assert_equal(expected, actual)        # Assert equality
assert_nil(value)                     # Assert nil
assert_empty(array)                   # Assert empty collection
assert_includes(array, item)          # Assert item in array

# Responses
assert_response :success              # 200 OK
assert_response :created              # 201 Created
assert_response :redirect             # 3xx Redirect
assert_response :unauthorized         # 401
assert_response :forbidden            # 403
assert_response :not_found            # 404
assert_response :unprocessable_entity # 422

# Redirects
assert_redirected_to root_path
assert_redirected_to controller: 'users', action: 'index'
assert_redirected_to user_path(@user)

# Content & HTML
assert_match(/pattern/, @response.body)
assert_select "selector"              # Element exists
assert_select "div#id"                # ID selector
assert_select "div", text: "content"  # Content match
assert_select "form" do              # Nested selectors
  assert_select "input[name=email]"
end

# Database
assert_difference('User.count', 1) { post users_path }
assert_no_difference('Post.count') { delete post_path }

# Cookies & Sessions
assert cookies[:session_id]           # Cookie exists
assert_empty cookies[:session_id]     # Cookie empty/nil
assert_equal value, cookies[:key]     # Cookie value match

# Time
assert_operator Time.current, :>, created_at  # Comparison operators
assert_in_delta(expected, actual, 5)          # Within range

# Raises
assert_raises(StandardError) { code_that_should_fail }

# Turbo Streams (custom, see turbo_ux_smoke_test.rb)
assert_turbo_replace("target_id")
assert_equal Mime[:turbo_stream].to_s, @response.media_type
```

---

## 10. SERVICES TO TEST

### SearchService
**Location:** `/app/services/search_service.rb`

**Methods:**
- `SearchService.perform(query, user, limit: 10)` - Returns hash of results
- `SearchService.count(query, user)` - Returns total count
- `SearchService.organized_results(query, user, limit: 10)` - Returns formatted response

**Searches Across:**
1. Transactions (description, category)
2. Daily Reports (work_title, yesterday, today, blockers, additional_details)
3. Projects (name, description)
4. Project Tasks (name)
5. Habits (name)
6. Shopping Items (name, quantity)
7. Budgets (category)
8. Anonymous Forms (title, description)

**Key Behaviors:**
- ✅ Case-insensitive LIKE queries
- ✅ User isolation (only returns user's own records)
- ✅ Respects limit parameter
- ✅ Returns empty hash for blank query

### AlertService
**Location:** `/app/services/alert_service.rb`

**Methods:**
- `AlertService.check_all_users()` - Check all users for alerts
- `AlertService.check_for_user(user)` - Check single user
- Private: `check_budget_exceeded(user)`
- Private: `check_no_reports_3_days(user)`
- Private: `check_project_no_progress(user)`
- Private: `create_notification(user, type, message)`

**Alert Types & Logic:**

1. **Budget Exceeded** `:budget_exceeded`
   - Trigger: Current month spending > monthly_limit
   - Logic: Sums transactions by category for current month
   
2. **No Reports (3 days)** `:no_report_3_days`
   - Trigger: No daily report in last 3 days
   - Config: `AlertsConfig::DAYS_WITHOUT_REPORT = 3`
   
3. **Project No Progress** `:project_no_progress`
   - Trigger: Project has no new tasks in 7+ days
   - Config: `AlertsConfig::DAYS_PROJECT_NO_PROGRESS` (inferred)

**Config File:** `/config/initializers/alerts.rb`
```ruby
DAYS_WITHOUT_REPORT = 3
DAYS_PROJECT_NO_PROGRESS = 7  # (inferred from use pattern)
```

---

## 11. TESTING SEARCHSERVICE

### Create Test File
```bash
touch test/services/search_service_test.rb
```

### Test Template
```ruby
require "test_helper"

class SearchServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  # Test: Empty query returns empty hash
  test "perform returns empty hash for blank query" do
    results = SearchService.perform("", @user)
    assert_equal({}, results)
    
    results = SearchService.perform("   ", @user)
    assert_equal({}, results)
  end

  # Test: Case-insensitive search
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

  # Test: Respects limit parameter
  test "perform respects limit parameter" do
    5.times do |i|
      @user.habits.create!(name: "Habit #{i}")
    end
    
    results = SearchService.perform("habit", @user, limit: 3)
    assert_equal 3, results[:habits].length
  end

  # Test: Searches transactions
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

  # Test: Searches projects
  test "perform searches projects by name" do
    @user.projects.create!(
      name: "Mobile App",
      description: "Build iOS app"
    )
    
    results = SearchService.perform("mobile", @user)
    assert results[:projects].count > 0
  end

  # Test: Searches daily reports
  test "perform searches daily reports by all fields" do
    @user.daily_reports.create!(
      report_date: Date.current,
      work_title: "Sprint Planning",
      worked_by: "Team",
      yesterday: "Completed tasks",
      today: "Planning meeting",
      blockers: "None"
    )
    
    results = SearchService.perform("planning", @user)
    assert results[:daily_reports].count > 0
  end

  # Test: User isolation
  test "perform respects user isolation" do
    other_user = users(:two)
    @user.habits.create!(name: "User One Habit")
    other_user.habits.create!(name: "User One Habit")
    
    results = SearchService.perform("user one", @user)
    results_other = SearchService.perform("user one", other_user)
    
    # Should only see own records
    assert_equal 1, results[:habits].count
    assert_equal 1, results_other[:habits].count
  end

  # Test: Count method
  test "count returns correct total" do
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

  # Test: Organized results format
  test "organized_results returns properly formatted hash" do
    @user.habits.create!(name: "Exercise")
    
    results = SearchService.organized_results("exercise", @user)
    
    assert_equal "exercise", results[:query]
    assert results[:total_count] > 0
    assert results[:results].is_a?(Hash)
  end
end
```

### Run Tests
```bash
rails test test/services/search_service_test.rb
rails test test/services/search_service_test.rb:12  # Run specific test
```

---

## 12. TESTING ALERTSERVICE

### Create Test File
```bash
touch test/services/alert_service_test.rb
```

### Test Template
```ruby
require "test_helper"

class AlertServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  # Budget exceeded alert
  test "check_budget_exceeded creates notification when exceeded" do
    budget = @user.budgets.create!(
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
  end

  # Budget doesn't duplicate notifications
  test "check_budget_exceeded prevents duplicate notifications" do
    budget = @user.budgets.create!(
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

  # Budget ignores other months
  test "check_budget_exceeded ignores budgets from other months" do
    past_month = (Time.zone.today - 1.month).beginning_of_month
    budget = @user.budgets.create!(
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

  # No reports alert when no recent report
  test "check_no_reports_3_days alerts when no recent reports" do
    AlertService.check_no_reports_3_days(@user)
    
    notification = @user.notifications.find_by(notification_type: :no_report_3_days)
    assert_not_nil notification
  end

  # No reports alert checks age
  test "check_no_reports_3_days alerts if last report is 3+ days old" do
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
    
    AlertService.check_no_reports_3_days(@user)
    
    notification = @user.notifications.find_by(notification_type: :no_report_3_days)
    assert_not_nil notification
  end

  # Project no progress alert
  test "check_project_no_progress alerts for stale projects" do
    project = @user.projects.create!(
      name: "Stale Project",
      description: "No recent tasks"
    )
    
    travel_to 8.days.ago do
      project.project_tasks.create!(name: "Old Task")
    end
    
    AlertService.check_project_no_progress(@user)
    
    notification = @user.notifications.find_by(notification_type: :project_no_progress)
    assert_not_nil notification
    assert_match(/Stale Project/, notification.message)
  end

  # Project no progress ignores active projects
  test "check_project_no_progress skips active projects" do
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

  # Check for single user runs all checks
  test "check_for_user runs all checks" do
    budget = @user.budgets.create!(
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
    
    assert @user.notifications.count > initial_count
  end

  # Check all users
  test "check_all_users runs checks for all users" do
    @user.budgets.create!(
      category: "entertainment",
      month: Time.zone.today.beginning_of_month,
      monthly_limit: 50
    )
    
    @user.transactions.create!(
      amount: 100,
      description: "Movie tickets",
      category: "entertainment",
      transaction_type: :expense,
      date: Date.current
    )
    
    initial_count = @user.notifications.count
    AlertService.check_all_users
    
    assert @user.notifications.count > initial_count
  end
end
```

### Run Tests
```bash
rails test test/services/alert_service_test.rb
rails test test/services/alert_service_test.rb:12  # Specific test
```

---

## 13. RUNNING TESTS LOCALLY

```bash
# All tests
rails test

# All tests verbose
rails test --verbose

# Specific file
rails test test/models/user_test.rb

# Specific test
rails test test/models/user_test.rb:12

# Pattern match
rails test test/services/

# System tests only
rails test:system

# With parallel workers
rails test --parallel=4

# Failing tests only
rails test --failing
```

### Test Output Example
```
$ rails test
Run options: --verbose

# Running tests with 4 parallel workers

TestSearchService
  test_perform_returns_empty_hash_for_blank_query PASS (0.42s)
  test_perform_is_case_insensitive PASS (0.38s)
  ...
  
Finished in 12.45s, 48 tests, 0 assertions

48 tests, 486 assertions, 0 failures, 0 errors
```

---

## 14. TESTING CHECKLIST FOR NEW TESTS

- [ ] Create test file in correct directory (test/services/, test/models/, etc.)
- [ ] Require test_helper at top
- [ ] Set up fixtures/test data in setup block
- [ ] Write one test per behavior (not multiple asserts per test)
- [ ] Use descriptive test names
- [ ] Clean up after tests (teardown if needed)
- [ ] Test both success AND failure cases
- [ ] Test edge cases (nil, empty, boundaries)
- [ ] Use meaningful assertions
- [ ] Mock external dependencies (if any)
- [ ] Run tests locally before committing
- [ ] Check CI/CD passes

---

## 15. BEST PRACTICES IN THIS APP

✅ **Following:**
1. Parallel testing enabled
2. Fixtures for consistent data
3. Custom helpers for common patterns
4. Integration tests for workflows
5. Turbo Stream assertions
6. CI/CD automation

⚠️ **Gaps to Address:**
1. Many model tests are empty (add test cases)
2. AlertService has no tests (critical business logic)
3. SearchService has no tests (complex queries)
4. CheckAlertsJob test is empty
5. No system/Capybara tests yet

---

## 16. QUICK REFERENCE: TEST CLASSES

| Class | Import | Best For | Methods |
|-------|--------|----------|---------|
| `ActiveSupport::TestCase` | Auto | Model logic, validations | `test`, `assert_equal` |
| `ActionDispatch::IntegrationTest` | Auto | Controller, routes, requests | `get/post/patch/delete`, `assert_response` |
| `ActionDispatch::SystemTestCase` | Optional | Browser automation | Capybara matchers |
| `ActiveJob::TestCase` | Auto | Background job logic | `perform_later`, `assert_enqueued_with` |
| `ActionView::TestCase` | Optional | View helpers | Helper method assertions |

---

## SUMMARY

This Rails 8.1 app uses **Minitest** with a solid foundation:
- ✅ Well-organized test structure
- ✅ Fixtures for data management
- ✅ Custom authentication helper
- ✅ Parallel testing enabled
- ✅ CI/CD pipeline

**Immediate needs:**
1. Add SearchService tests (test/services/search_service_test.rb)
2. Add AlertService tests (test/services/alert_service_test.rb)
3. Fill empty model/job tests
4. Create test/services/ directory

Use the templates above as starting points for comprehensive test coverage!

