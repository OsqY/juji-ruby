require "test_helper"

class ChatRoomTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @other = users(:two)
    @room = ChatRoom.create!(name: "Test Room", owner: @user, room_type: :open)
    @room.add_member(@user, role: :owner)
  end

  test "valid room" do
    assert @room.valid?
  end

  test "requires name" do
    room = ChatRoom.new(name: "", owner: @user)
    assert_not room.valid?
  end

  test "generates token on create" do
    assert @room.token.present?
  end

  test "member? returns true for member" do
    assert @room.member?(@user)
    assert_not @room.member?(@other)
  end

  test "can_join? allows new user when not full" do
    assert @room.can_join?(@other)
  end

  test "can_join? rejects when full" do
    room = ChatRoom.create!(name: "Small", owner: @user, room_type: :open, capacity: 1)
    room.add_member(@user, role: :owner)
    assert_not room.can_join?(@other)
  end

  test "can_join? rejects existing member" do
    assert_not @room.can_join?(@user)
  end

  test "open room allows speaking for members" do
    @room.add_member(@other)
    assert @room.can_speak?(@other)
  end

  test "channel only allows speaking for admins and owners" do
    channel = ChatRoom.create!(name: "Channel", owner: @user, room_type: :channel)
    channel.add_member(@user, role: :owner)
    channel.add_member(@other, role: :member)
    assert channel.can_speak?(@user)
    assert_not channel.can_speak?(@other)
  end
end
