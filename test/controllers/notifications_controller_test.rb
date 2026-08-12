require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other = users(:two)
  end

  test "authenticated user sees only their notifications" do
    notification = @user.notifications.create!(
      notification_type: :budget_exceeded,
      message: "Budget warning"
    )
    @other.notifications.create!(
      notification_type: :budget_exceeded,
      message: "Other user's notification"
    )

    sign_in_as(@user)
    get notifications_path

    assert_response :success
    assert_match notification.message, response.body
    assert_no_match(/Other user's notification/, response.body)
  end

  test "authenticated user can mark one notification as read" do
    notification = @user.notifications.create!(
      notification_type: :budget_exceeded,
      message: "Budget warning"
    )

    sign_in_as(@user)
    patch mark_as_read_notification_path(notification)

    assert_redirected_to notifications_path
    assert notification.reload.read_at.present?
  end

  test "marking all notifications as read does not affect another user" do
    notification = @user.notifications.create!(
      notification_type: :budget_exceeded,
      message: "Budget warning"
    )
    other_notification = @other.notifications.create!(
      notification_type: :budget_exceeded,
      message: "Other user's notification"
    )

    sign_in_as(@user)
    patch mark_all_as_read_notifications_path

    assert_redirected_to notifications_path
    assert notification.reload.read_at.present?
    assert_nil other_notification.reload.read_at
  end

  test "notifications require authentication" do
    get notifications_path

    assert_redirected_to new_session_path
  end
end
