require "test_helper"

class WhiteboardChannelTest < ActionCable::Channel::TestCase
  setup do
    @owner = users(:one)
    @collaborator = users(:two)
    @whiteboard = @owner.whiteboards.create!(name: "Test Board")
  end

  test "subscribes when user is owner" do
    stub_connection(current_user: @owner)
    subscribe(whiteboard_id: @whiteboard.id)
    assert subscription.confirmed?
    assert_has_stream_for @whiteboard
  end

  test "subscribes when user is collaborator" do
    @whiteboard.add_collaborator(@collaborator)
    stub_connection(current_user: @collaborator)
    subscribe(whiteboard_id: @whiteboard.id)
    assert subscription.confirmed?
  end

  test "subscribes with valid token without being collaborator" do
    stub_connection(current_user: @collaborator)
    subscribe(whiteboard_id: @whiteboard.id, token: @whiteboard.token)
    assert subscription.confirmed?
  end

  test "rejects subscription for unauthorized user" do
    other = User.create!(email_address: "other@example.com", password: "password123", password_confirmation: "password123")
    stub_connection(current_user: other)
    subscribe(whiteboard_id: @whiteboard.id)
    assert subscription.rejected?
  end

  test "draw action creates stroke and broadcasts" do
    stub_connection(current_user: @owner)
    subscribe(whiteboard_id: @whiteboard.id)

    stroke_data = { "tool" => "pen", "color" => "#000", "width" => 3, "points" => [[0, 0], [10, 10]] }

    assert_difference -> { @whiteboard.whiteboard_strokes.count }, 1 do
      perform :draw, stroke: stroke_data
    end

    assert_broadcast_on(@whiteboard, {
      type: "stroke",
      stroke: stroke_data,
      user_id: @owner.id,
      stroke_id: @whiteboard.whiteboard_strokes.last.id
    })
  end

  test "clear action destroys all strokes and broadcasts" do
    @whiteboard.whiteboard_strokes.create!(user: @owner, stroke_data: { "points" => [[0, 0]] })
    stub_connection(current_user: @owner)
    subscribe(whiteboard_id: @whiteboard.id)

    assert_difference -> { @whiteboard.whiteboard_strokes.count }, -1 do
      perform :clear
    end

    assert_broadcast_on(@whiteboard, { type: "clear" })
  end

  test "non-owner cannot clear" do
    @whiteboard.add_collaborator(@collaborator)
    @whiteboard.whiteboard_strokes.create!(user: @owner, stroke_data: { "points" => [[0, 0]] })
    stub_connection(current_user: @collaborator)
    subscribe(whiteboard_id: @whiteboard.id)

    assert_no_difference -> { @whiteboard.whiteboard_strokes.count } do
      perform :clear
    end
  end
end
