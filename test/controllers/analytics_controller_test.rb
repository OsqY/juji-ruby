require "test_helper"

class AnalyticsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "should get index" do
    get analytics_url
    assert_response :success
  end

  test "should return json data for spending_monthly" do
    get analytics_data_url(metric: "spending_monthly")
    assert_response :success
    body = JSON.parse(response.body)
    assert body.is_a?(Hash)
  end

  test "should return json data for spending_category" do
    get analytics_data_url(metric: "spending_category")
    assert_response :success
    body = JSON.parse(response.body)
    assert body.is_a?(Hash)
  end

  test "should return json data for habit_completion" do
    get analytics_data_url(metric: "habit_completion")
    assert_response :success
    body = JSON.parse(response.body)
    assert body.is_a?(Hash)
  end

  test "should return json data for weekly_balance" do
    get analytics_data_url(metric: "weekly_balance")
    assert_response :success
    body = JSON.parse(response.body)
    assert body.is_a?(Hash)
  end

  test "should return empty hash for unknown metric" do
    get analytics_data_url(metric: "unknown")
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal({}, body)
  end

  test "requires authentication" do
    delete session_path
    get analytics_url
    assert_redirected_to new_session_path
  end

  private
    def sign_in_as(user)
      post session_path, params: { email_address: user.email_address, password: "password" }
    end
end
