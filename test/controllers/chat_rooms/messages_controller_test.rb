require "test_helper"

module ChatRooms
  class MessagesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:one)
      @other = users(:two)
      @room = ChatRoom.create!(name: "Room", owner: @user, room_type: :open)
      @room.add_member(@user, role: :owner)
    end

    test "requires authentication" do
      post chat_room_messages_url(@room), params: { message: { content: "Hi" } }
      assert_redirected_to new_session_path
    end

    test "member can create message" do
      sign_in_as(@user)
      assert_difference("Message.count") do
        post chat_room_messages_url(@room), params: { message: { content: "Hello" } }
      end
      assert_redirected_to chat_room_url(@room)
    end

    test "non-member cannot create message" do
      @room.chat_room_members.find_by(user: @user).destroy
      sign_in_as(@user)
      assert_no_difference("Message.count") do
        post chat_room_messages_url(@room), params: { message: { content: "Hello" } }
      end
      assert_response :not_found
    end

    test "cannot post to non-existent room" do
      sign_in_as(@user)
      post chat_room_messages_url(chat_room_id: 999999), params: { message: { content: "Hello" } }
      assert_response :not_found
    end

    private
      def sign_in_as(user)
        post session_path, params: { email_address: user.email_address, password: "password" }
      end
  end
end
