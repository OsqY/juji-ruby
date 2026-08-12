# Testing Documentation for Rails 8.1 App

## Critical browser journeys

Run the reproducible browser matrix with:

```bash
RAILS_ENV=test bin/rails db:test:prepare test:system
```

It uses Rails system tests, Capybara, and headless Chrome already present in
the test bundle. Browser tests run with one worker because the test database
is SQLite and the Rails system-test server owns the browser session. Failed
tests leave screenshots and HTML diagnostics in `tmp/screenshots`.

The suite covers authentication/session expiry, authorization, daily reports,
transactions and budgets, project tasks, habits, shopping, goals, exports,
notifications, public forms, invitations, chat delivery, and whiteboard
peer delivery. Socket delivery itself still requires a running Action Cable
backend; the browser suite asserts connection and delivery evidence instead
of silently skipping when that external service is unavailable.

This folder contains comprehensive testing documentation and ready-to-use test templates for your Rails 8.1 application.

## 📚 Documentation Files

### 1. **TESTING_SUMMARY.txt** ← START HERE
   - **Purpose**: Executive overview and quick reference
   - **Length**: ~400 lines
   - **Contains**: 
     - Framework overview (Minitest, Ruby 4.0.1, Rails 8.1.2)
     - Current test structure breakdown
     - Service coverage status ⚠️
     - CI/CD pipeline details
     - Key assertions reference
     - Immediate action items
   - **Best for**: Quick answers and big-picture understanding

### 2. **TESTING_ANALYSIS.md** ← COMPREHENSIVE GUIDE
   - **Purpose**: Complete testing setup documentation
   - **Length**: ~2000 lines (comprehensive)
   - **Contains**:
     - Detailed framework explanation
     - Full directory structure with 23 test files
     - test_helper.rb and custom helpers breakdown
     - Database configuration
     - All testing patterns used in codebase
     - Fixture system explanation
     - CI/CD configuration details
     - Naming conventions table
     - Complete assertions reference
     - SearchService & AlertService analysis
     - Best practices and gaps
   - **Best for**: Deep understanding, reference documentation, learning patterns

### 3. **TESTING_QUICK_START.md** ← COPY & PASTE TEMPLATES
   - **Purpose**: Ready-to-use test templates
   - **Length**: ~1000 lines (practical)
   - **Contains**:
     - Step-by-step setup instructions
     - SearchService test (full implementation, 25+ test cases)
     - AlertService test (full implementation, 18+ test cases)
     - Fixture examples
     - How to run tests
     - Debugging guide
     - Next steps checklist
   - **Best for**: Implementing tests immediately, copy-paste ready code

---

## 🎯 Quick Navigation

### "What is the testing framework?"
→ See **TESTING_SUMMARY.txt** § 1

### "How do I write a test for SearchService?"
→ See **TESTING_QUICK_START.md** § STEP 2

### "What assertions are available?"
→ See **TESTING_SUMMARY.txt** § 7 or **TESTING_ANALYSIS.md** § 9

### "How does authentication work in tests?"
→ See **TESTING_ANALYSIS.md** § 3

### "What's the test directory structure?"
→ See **TESTING_ANALYSIS.md** § 2 or **TESTING_SUMMARY.txt** § 2

### "How does CI/CD testing work?"
→ See **TESTING_SUMMARY.txt** § 6 or **TESTING_ANALYSIS.md** § 7

### "What tests are missing?"
→ See **TESTING_SUMMARY.txt** § 9 or **TESTING_ANALYSIS.md** § 11

---

## 🚀 Get Started in 5 Minutes

```bash
# 1. Create services test directory
mkdir -p test/services

# 2. Create SearchService test
# Copy the template from TESTING_QUICK_START.md § STEP 2
# into test/services/search_service_test.rb

# 3. Create AlertService test
# Copy the template from TESTING_QUICK_START.md § STEP 3
# into test/services/alert_service_test.rb

# 4. Run tests
rails test test/services/

# 5. Fix any failures
# (usually just fixture/data issues)

# 6. Commit
git add test/services/
git commit -m "Add SearchService and AlertService tests"
```

---

## 📋 Current Testing Status

### ✅ Working Well
- Controller tests (8 files with good coverage)
- Integration tests (4 files testing Turbo Streams)
- Session/authentication helper
- Parallel test execution
- Fixtures (YAML-based)
- CI/CD automation (GitHub Actions)

### ⚠️ Critical Gaps
- **SearchService** - No tests (global search functionality)
- **AlertService** - No tests (notification logic)
- **CheckAlertsJob** - Empty test file
- **Model tests** - Mostly empty (8 files with just placeholders)

### 📊 Test Coverage Summary
```
Total test code: ~1006 lines
Controllers:     8 test files ✅
Models:          8 test files (mostly empty) ⚠️
Integration:     4 test files ✅
Jobs:            1 test file (empty) ⚠️
Services:        0 test files ⚠️ CRITICAL
```

---

## 🔧 Testing Framework Details

| Aspect | Details |
|--------|---------|
| **Framework** | Minitest (Rails 8.1 default) |
| **Ruby Version** | 4.0.1 |
| **Rails Version** | 8.1.2 |
| **Database** | SQLite3 (test env) |
| **Parallel Testing** | ✅ Enabled |
| **Fixtures** | YAML-based in test/fixtures/ |
| **Custom Helpers** | test/test_helpers/session_test_helper.rb |
| **CI/CD** | GitHub Actions (.github/workflows/ci.yml) |

---

## 🧪 Testing Patterns

### Pattern 1: Model Tests
```ruby
class UserTest < ActiveSupport::TestCase
  test "validates email" do
    user = User.new(email: "test@example.com")
    assert user.valid?
  end
end
```

### Pattern 2: Controller/Integration Tests
```ruby
class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "create redirects when valid" do
    post session_path, params: { email: "test@example.com", password: "password" }
    assert_redirected_to root_path
  end
end
```

### Pattern 3: Turbo Stream Tests
```ruby
class HabitsTest < ActionDispatch::IntegrationTest
  test "create returns turbo stream" do
    post habits_path, params: { habit: { name: "Read" } }, 
         headers: { "Accept" => Mime[:turbo_stream].to_s }
    assert_response :success
  end
end
```

---

## 📖 Common Commands

```bash
# Run all tests
rails test

# Run specific file
rails test test/models/user_test.rb

# Run specific test
rails test test/models/user_test.rb:5

# Run with pattern
rails test test/services/

# Run system tests
rails test:system

# Run with verbose output
rails test --verbose

# Run parallel with N workers
rails test --parallel=4
```

---

## 🔍 Key Files in Test Structure

```
test/
├── test_helper.rb                          # Main configuration
│   ├── Enables parallel testing
│   ├── Loads all fixtures
│   └── Includes SessionTestHelper
│
├── test_helpers/session_test_helper.rb    # Auth helper
│   ├── sign_in_as(user)
│   └── sign_out()
│
├── controllers/                            # 8 controller tests
│   └── sessions_controller_test.rb        # Best example
│
├── models/                                 # 8 model tests (mostly empty)
│   └── user_test.rb                       # Only one with real test
│
├── integration/                            # 4 integration tests
│   └── turbo_ux_smoke_test.rb             # Best example
│
├── jobs/                                   # 1 job test (empty)
│   └── check_alerts_job_test.rb
│
├── services/                               # ⚠️ EMPTY - NEEDS TESTS
│   └── (create this directory)
│
└── fixtures/                               # YAML test data
    ├── users.yml
    ├── habits.yml
    ├── projects.yml
    └── ... 5 more
```

---

## 🎓 Learning Resources Within These Docs

### For Understanding Minitest
→ **TESTING_ANALYSIS.md** § 5 (Complete patterns)

### For Understanding Fixtures
→ **TESTING_ANALYSIS.md** § 6 (Fixture system)

### For Understanding Assertions
→ **TESTING_SUMMARY.txt** § 7 (Quick reference)
→ **TESTING_ANALYSIS.md** § 9 (Comprehensive reference)

### For Understanding Services
→ **TESTING_SUMMARY.txt** § 4 (Service analysis)
→ **TESTING_ANALYSIS.md** § 10-11 (Full service tests)

### For Understanding CI/CD
→ **TESTING_SUMMARY.txt** § 6
→ **TESTING_ANALYSIS.md** § 7

---

## ✨ Services Needing Tests

### SearchService
**File**: `/app/services/search_service.rb`

**What it does**:
- Global search across 8 models
- Case-insensitive LIKE queries
- User-scoped results
- Returns organized results

**Methods**:
- `SearchService.perform(query, user, limit: 10)`
- `SearchService.count(query, user)`
- `SearchService.organized_results(query, user, limit: 10)`

**Test template**: Available in **TESTING_QUICK_START.md** § STEP 2

---

### AlertService
**File**: `/app/services/alert_service.rb`

**What it does**:
- Creates notifications for budget exceeding
- Notifies users about missing reports (3+ days)
- Alerts for inactive projects (7+ days)
- Prevents duplicate notifications

**Methods**:
- `AlertService.check_all_users()`
- `AlertService.check_for_user(user)`
- Private: `check_budget_exceeded(user)`
- Private: `check_no_reports_3_days(user)`
- Private: `check_project_no_progress(user)`

**Test template**: Available in **TESTING_QUICK_START.md** § STEP 3

---

## 🎬 Next Steps

1. **Read** TESTING_SUMMARY.txt (5 min read)
2. **Review** existing tests in test/controllers/ and test/integration/
3. **Copy** SearchService tests from TESTING_QUICK_START.md
4. **Copy** AlertService tests from TESTING_QUICK_START.md
5. **Create** test/services/ directory
6. **Run** `rails test test/services/`
7. **Debug** any failures
8. **Commit** changes

---

## 📞 Questions?

- **"Is Minitest the right choice?"** → See TESTING_SUMMARY.txt § 1
- **"How do I test SearchService?"** → See TESTING_QUICK_START.md § STEP 2
- **"What's the expected output?"** → See TESTING_QUICK_START.md § STEP 6
- **"How do I debug a failing test?"** → See TESTING_QUICK_START.md § STEP 6
- **"What fixtures do I need?"** → See TESTING_ANALYSIS.md § 6

---

## File Reference

| File | Read Time | Best For | Depth |
|------|-----------|----------|-------|
| TESTING_SUMMARY.txt | 10 min | Quick reference & overview | 400 lines |
| TESTING_ANALYSIS.md | 30 min | Learning & complete guide | 2000 lines |
| TESTING_QUICK_START.md | 15 min | Implementing tests now | 1000 lines |

---

**Last Updated**: March 21, 2024
**Rails Version**: 8.1.2
**Ruby Version**: 4.0.1
**Framework**: Minitest (default)

Happy testing! 🚀
