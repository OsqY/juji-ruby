require "test_helper"

class ChatRoomsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    log_in_as(@user)
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

  private
    def log_in_as(user)
      post session_url, params: { email_address: user.email_address, password: "password" }
    end
end
