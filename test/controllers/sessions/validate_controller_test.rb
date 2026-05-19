require "test_helper"

module Sessions
  class ValidateControllerTest < ActionDispatch::IntegrationTest
    test "returns user info when authenticated" do
      user = users(:one)
      sign_in_as(user)
      get sessions_validate_url
      assert_response :success
      body = JSON.parse(response.body)
      assert body["authenticated"]
      assert_equal user.id, body["user"]["id"]
      assert_equal user.email_address, body["user"]["email"]
    end

    test "returns unauthorized when not authenticated" do
      get sessions_validate_url
      assert_response :unauthorized
      body = JSON.parse(response.body)
      assert_not body["authenticated"]
    end

    private
      def sign_in_as(user)
        post session_path, params: { email_address: user.email_address, password: "password" }
      end
  end
end
