require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other = users(:two)
  end

  test "notification actions require authentication" do
    notification = notifications(:one)

    get notifications_path
    assert_redirected_to new_session_path

    patch mark_as_read_notification_path(notification)
    assert_redirected_to new_session_path

    patch mark_all_as_read_notifications_path
    assert_redirected_to new_session_path
  end

  test "index shows only the 20 most recent notifications for the user" do
    sign_in_as(@user)
    @user.notifications.delete_all

    21.times do |index|
      @user.notifications.create!(
        notification_type: :budget_exceeded,
        message: "Notification #{index}",
        created_at: index.minutes.ago
      )
    end
    @other.notifications.create!(
      notification_type: :budget_exceeded,
      message: "Other user's notification"
    )

    get notifications_path

    assert_response :success
    assert_select ".aws-list-item", count: 20
    assert_includes response.body, "Notification 0"
    assert_not_includes response.body, "Notification 20"
    assert_not_includes response.body, "Other user's notification"
  end

  test "user can mark their notification as read" do
    sign_in_as(@user)
    notification = @user.notifications.create!(
      notification_type: :budget_exceeded,
      message: "Budget exceeded"
    )

    patch mark_as_read_notification_path(notification)

    assert_redirected_to notifications_path
    assert notification.reload.read_at.present?
  end

  test "mark all as read only updates the current user's notifications" do
    sign_in_as(@user)
    own_notification = @user.notifications.create!(
      notification_type: :budget_exceeded,
      message: "Budget exceeded"
    )
    other_notification = @other.notifications.create!(
      notification_type: :budget_exceeded,
      message: "Other budget exceeded"
    )

    patch mark_all_as_read_notifications_path

    assert_redirected_to notifications_path
    assert own_notification.reload.read_at.present?
    assert_nil other_notification.reload.read_at
  end

  test "user cannot mark another user's notification as read" do
    sign_in_as(@user)
    notification = @other.notifications.create!(
      notification_type: :budget_exceeded,
      message: "Private notification"
    )

    patch mark_as_read_notification_path(notification)

    assert_response :not_found
    assert_nil notification.reload.read_at
  end
end
