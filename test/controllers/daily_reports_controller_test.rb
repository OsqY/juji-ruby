require "test_helper"

class DailyReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)

    @daily_report = @user.daily_reports.create!(
      report_date: Date.current,
      work_title: "Estado diario",
      worked_by: "Tester",
      yesterday: "Avance previo",
      today: "Trabajo actual",
      blockers: ""
    )
  end

  test "should get index" do
    get daily_reports_path
    assert_response :success
  end

  test "should get show" do
    get daily_report_path(@daily_report)
    assert_response :success
  end

  test "should get new" do
    get new_daily_report_path
    assert_response :success
  end

  test "should get edit" do
    get edit_daily_report_path(@daily_report)
    assert_response :success
  end

  test "creates a report and records its insight notification" do
    assert_difference("DailyReport.count", 1) do
      post daily_reports_path, params: {
        daily_report: {
          report_date: Date.current + 1.day,
          work_title: "Created report",
          worked_by: "Tester",
          yesterday: "Previous work",
          today: "Current work",
          blockers: ""
        }
      }
    end

    assert_redirected_to daily_reports_path
    assert @user.notifications.exists?(notification_type: :insight)
  end

  test "creates a report when post-save tracking fails" do
    original_record_activity = UserStreak.method(:record_activity!)
    UserStreak.define_singleton_method(:record_activity!) { |*| raise StandardError, "tracking unavailable" }

    begin
      assert_difference("DailyReport.count", 1) do
        post daily_reports_path, params: {
          daily_report: {
            report_date: Date.current + 1.day,
            work_title: "Saved despite tracking failure",
            worked_by: "Tester",
            yesterday: "Previous work",
            today: "Current work",
            blockers: ""
          }
        }
      end
    ensure
      UserStreak.define_singleton_method(:record_activity!, original_record_activity)
    end

    assert_redirected_to daily_reports_path
    assert @user.notifications.exists?(notification_type: :insight)
  end
end
