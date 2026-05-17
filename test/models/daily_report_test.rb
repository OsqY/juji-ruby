require "test_helper"

class DailyReportTest < ActiveSupport::TestCase
  test "validates report_date presence" do
    report = DailyReport.new(report_date: nil)
    assert_not report.valid?
    assert_includes report.errors[:report_date], "no puede estar en blanco"
  end

  test "validates uniqueness of report_date per user" do
    existing = daily_reports(:one)
    report = DailyReport.new(
      user: existing.user,
      report_date: existing.report_date,
      work_title: "Test",
      worked_by: "Test",
      yesterday: "Test",
      today: "Test"
    )
    assert_not report.valid?
    assert_includes report.errors[:report_date], "ya tiene un reporte para esta fecha"
  end

  test "belongs to user" do
    report = daily_reports(:one)
    assert report.user.present?
  end

  test "validates photo content type" do
    report = daily_reports(:one)
    report.photo.attach(
      io: StringIO.new("test"),
      filename: "test.txt",
      content_type: "text/plain"
    )
    assert_not report.valid?
    assert_includes report.errors[:photo], "debe ser una imagen (JPEG, PNG, GIF, WebP)"
  end
end
