require "test_helper"

class FriendsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other = users(:two)
  end

  test "index requires authentication" do
    get friends_url
    assert_redirected_to new_session_path
  end

  test "authenticated user sees friends index" do
    sign_in_as(@user)
    get friends_url
    assert_response :success
  end

  test "pending requires authentication" do
    get pending_friends_url
    assert_redirected_to new_session_path
  end

  test "authenticated user sees pending requests" do
    sign_in_as(@user)
    get pending_friends_url
    assert_response :success
  end

  test "accept received friend request" do
    friendship = @user.friendships_requested.create!(addressee: @other, status: :pending)
    sign_in_as(@other)
    post accept_friends_url, params: { id: friendship.id }
    assert_redirected_to friends_url
    assert friendship.reload.accepted?
  end

  test "reject received friend request" do
    friendship = @user.friendships_requested.create!(addressee: @other, status: :pending)
    sign_in_as(@other)
    post reject_friends_url, params: { id: friendship.id }
    assert_redirected_to friends_url
    assert friendship.reload.rejected?
  end

  test "destroy friendship" do
    friendship = @user.friendships_requested.create!(addressee: @other, status: :accepted)
    sign_in_as(@user)
    assert_difference("Friendship.count", -1) do
      delete friend_url(friendship)
    end
    assert_redirected_to friends_url
  end

  test "cannot destroy friendship of other users" do
    third = User.create!(email_address: "third@example.com", password: "password", invite_token: SecureRandom.urlsafe_base64(16))
    friendship = @user.friendships_requested.create!(addressee: @other, status: :accepted)
    sign_in_as(third)
    assert_no_difference("Friendship.count") do
      delete friend_url(friendship)
    end
    assert_redirected_to friends_url
  end

  test "accept user invite via token" do
    sign_in_as(@other)
    get user_invite_url(token: @user.invite_token)
    assert_redirected_to friends_url
    assert @other.friendship_with(@user).present?
  end

  test "cannot invite self" do
    sign_in_as(@user)
    get user_invite_url(token: @user.invite_token)
    assert_redirected_to friends_url
  end

  private
    def sign_in_as(user)
      post session_path, params: { email_address: user.email_address, password: "password" }
    end
end
