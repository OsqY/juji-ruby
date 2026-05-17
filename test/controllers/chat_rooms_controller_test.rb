require "test_helper"

class ChatRoomsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "should get index" do
    get chat_rooms_url
    assert_response :success
  end

  test "should get new" do
    get new_chat_room_url
    assert_response :success
  end

  test "should create chat_room" do
    assert_difference("ChatRoom.count") do
      post chat_rooms_url, params: { chat_room: { name: "New Room", room_type: "open" } }
    end
    assert_redirected_to chat_room_url(ChatRoom.last)
  end

  test "should show chat_room" do
    room = ChatRoom.create!(name: "Room", owner: @user, room_type: :open)
    room.add_member(@user, role: :owner)
    get chat_room_url(room)
    assert_response :success
  end

  test "should join chat_room" do
    room = ChatRoom.create!(name: "Room", owner: users(:two), room_type: :open)
    post join_chat_room_url(room)
    assert_redirected_to chat_room_url(room)
  end

  test "should leave chat_room" do
    room = ChatRoom.create!(name: "Room", owner: @user, room_type: :open)
    room.add_member(@user, role: :owner)
    post leave_chat_room_url(room)
    assert_redirected_to chat_rooms_url
  end

  test "owner can destroy room" do
    room = ChatRoom.create!(name: "Room", owner: @user, room_type: :open)
    room.add_member(@user, role: :owner)
    delete chat_room_url(room)
    assert_redirected_to chat_rooms_url
    assert room.reload.archived_at.present?
  end

  test "non-owner cannot destroy room" do
    room = ChatRoom.create!(name: "Room", owner: users(:two), room_type: :open)
    room.add_member(@user, role: :member)
    delete chat_room_url(room)
    assert_redirected_to chat_room_url(room)
    assert room.reload.archived_at.nil?
  end

  test "owner can invite" do
    room = ChatRoom.create!(name: "Room", owner: @user, room_type: :open)
    room.add_member(@user, role: :owner)
    post invite_chat_room_url(room)
    assert_redirected_to public_chat_room_url(token: room.token)
  end

  test "non-admin cannot invite" do
    room = ChatRoom.create!(name: "Room", owner: users(:two), room_type: :open)
    room.add_member(@user, role: :member)
    post invite_chat_room_url(room)
    assert_redirected_to chat_room_url(room)
  end

  test "owner can kick member" do
    room = ChatRoom.create!(name: "Room", owner: @user, room_type: :open)
    room.add_member(@user, role: :owner)
    room.add_member(users(:two), role: :member)
    delete kick_chat_room_url(room), params: { user_id: users(:two).id }
    assert_redirected_to chat_room_url(room)
    assert_not room.member?(users(:two))
  end

  test "cannot kick owner" do
    room = ChatRoom.create!(name: "Room", owner: @user, room_type: :open)
    room.add_member(@user, role: :owner)
    delete kick_chat_room_url(room), params: { user_id: @user.id }
    assert_redirected_to chat_room_url(room)
  end

  test "public show with token" do
    room = ChatRoom.create!(name: "Room", owner: @user, room_type: :open)
    get public_chat_room_url(token: room.token)
    assert_response :success
  end

  test "public join authenticated" do
    room = ChatRoom.create!(name: "Room", owner: users(:two), room_type: :open)
    post public_chat_room_join_url(token: room.token)
    assert_redirected_to chat_room_url(room)
    assert room.member?(@user)
  end

  private
    def sign_in_as(user)
      post session_url, params: { email_address: user.email_address, password: "password" }
    end
end
