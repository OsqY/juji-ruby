require "test_helper"

class WhiteboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other = users(:two)
    @whiteboard = @user.whiteboards.create!(name: "Test Board")
  end

  test "index requires authentication" do
    get whiteboards_path
    assert_redirected_to new_session_path
  end

  test "authenticated user sees their whiteboards" do
    sign_in_as(@user)
    get whiteboards_path
    assert_response :success
    assert_select "h1", /PIZARRAS/
  end

  test "new requires authentication" do
    get new_whiteboard_path
    assert_redirected_to new_session_path
  end

  test "authenticated user can access new" do
    sign_in_as(@user)
    get new_whiteboard_path
    assert_response :success
  end

  test "create whiteboard" do
    sign_in_as(@user)
    assert_difference -> { Whiteboard.count }, 1 do
      post whiteboards_path, params: { whiteboard: { name: "New Board" } }
    end
    assert_redirected_to whiteboard_path(Whiteboard.last)
  end

  test "show requires access" do
    sign_in_as(@other)
    get whiteboard_path(@whiteboard)
    assert_redirected_to whiteboards_path
  end

  test "owner can view whiteboard" do
    sign_in_as(@user)
    get whiteboard_path(@whiteboard)
    assert_response :success
    assert_select "h1", /TEST BOARD/
  end

  test "collaborator can view whiteboard" do
    @whiteboard.add_collaborator(@other)
    sign_in_as(@other)
    get whiteboard_path(@whiteboard)
    assert_response :success
  end

  test "public show with token" do
    get public_whiteboard_path(token: @whiteboard.token)
    assert_response :success
    assert_select "h1", /TEST BOARD/
  end

  test "destroy whiteboard" do
    sign_in_as(@user)
    assert_difference -> { Whiteboard.count }, -1 do
      delete whiteboard_path(@whiteboard)
    end
    assert_redirected_to whiteboards_path
  end

  test "non-owner cannot destroy" do
    sign_in_as(@other)
    assert_no_difference -> { Whiteboard.count } do
      delete whiteboard_path(@whiteboard)
    end
    assert_redirected_to whiteboards_path
  end

  private
    def sign_in_as(user)
      post session_path, params: { email_address: user.email_address, password: "password" }
    end
end
