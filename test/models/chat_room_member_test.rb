require "test_helper"

class ChatRoomMemberTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @room = ChatRoom.create!(name: "Room", owner: @user, room_type: :open)
  end

  test "unique membership" do
    @room.add_member(@user)
    assert_raises(ActiveRecord::RecordInvalid) do
      @room.add_member(@user)
    end
  end
end
