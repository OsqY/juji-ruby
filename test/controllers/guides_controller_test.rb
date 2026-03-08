require "test_helper"

class GuidesControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get guide_path
    assert_redirected_to new_session_path
  end

  test "shows guide for authenticated user" do
    sign_in_as(users(:one))

    get guide_path

    assert_response :success
    assert_select "h1", /guia de funcionalidades/i
  end
end
