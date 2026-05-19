require "test_helper"

class PushNotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "register stores fcm token" do
    post push_notifications_register_url, params: { fcm_token: "test-token-123" }
    assert_response :success
    assert_equal "test-token-123", @user.reload.fcm_token
  end

  test "register rejects blank token" do
    post push_notifications_register_url, params: { fcm_token: " " }
    assert_response :unprocessable_entity
  end

  test "unregister clears fcm token" do
    @user.update_column(:fcm_token, "existing-token")
    delete push_notifications_unregister_url
    assert_response :success
    assert_nil @user.reload.fcm_token
  end

  test "requires authentication" do
    delete session_path
    post push_notifications_register_url, params: { fcm_token: "token" }
    assert_redirected_to new_session_path
  end

  private
    def sign_in_as(user)
      post session_path, params: { email_address: user.email_address, password: "password" }
    end
end
