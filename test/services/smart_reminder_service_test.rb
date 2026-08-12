require "test_helper"

class SmartReminderServiceTest < ActiveSupport::TestCase
  test "records a reminder notification when a habit is incomplete" do
    user = users(:one)
    user.update!(email_frequency: "daily", last_email_sent_at: nil)
    user.daily_reports.create!(
      report_date: Date.current - 1.day,
      work_title: "Yesterday",
      worked_by: "Tester",
      yesterday: "Previous work",
      today: "Current work",
      blockers: ""
    )
    user.habits.create!(name: "Exercise")

    assert_difference("Notification.count", 1) do
      SmartReminderService.check_daily_reminders(user)
    end

    assert user.notifications.order(:created_at).last.reminder?
  end
end
