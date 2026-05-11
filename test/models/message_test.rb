require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @room = ChatRoom.create!(name: "Room", owner: @user, room_type: :open)
    @room.add_member(@user, role: :owner)
  end

  test "valid message" do
    msg = @room.messages.new(user: @user, content: "Hello")
    assert msg.valid?
  end

  test "requires content" do
    msg = @room.messages.new(user: @user, content: "")
    assert_not msg.valid?
  end
end
