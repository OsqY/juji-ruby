require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  test "belongs to user" do
    notification = notifications(:one)
    assert notification.user.present?
  end

  test "unread scope returns unread notifications" do
    user = users(:one)
    unread = user.notifications.unread
    assert unread.all? { |n| n.read_at.nil? }
  end

  test "mark_as_read sets read_at" do
    notification = Notification.create!(
      user: users(:one),
      notification_type: :budget_exceeded,
      message: "Test message",
      read_at: nil
    )
    assert_nil notification.read_at
    notification.mark_as_read!
    assert notification.read_at.present?
  end
end
