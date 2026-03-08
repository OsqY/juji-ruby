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
end
