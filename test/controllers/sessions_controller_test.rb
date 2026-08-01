require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "public pages have usable CSP nonces and no native nav overlay" do
    get new_session_path, headers: { "User-Agent" => "TurboNative/1.0" }

    assert_response :success
    assert_select "script[nonce]" do |scripts|
      assert scripts.all? { |script| script["nonce"].present? }
    end
    assert_not_includes response.body, 'nonce=""'
    assert_not_includes response.body, 'class="chaos-nav mobile-nav"'
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_response :unprocessable_entity
    assert_select "div", /try another email address or password/i
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
