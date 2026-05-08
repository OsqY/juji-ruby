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

    stroke_data = { "tool" => "pen", "color" => "#000", "width" => 3, "points" => [ [ 0, 0 ], [ 10, 10 ] ] }

    assert_difference -> { @whiteboard.whiteboard_strokes.count }, 1 do
      perform :draw, stroke: stroke_data, client_id: "test-client-id"
    end

    assert_broadcast_on(@whiteboard, {
      type: "stroke",
      stroke: stroke_data,
      user_id: @owner.id,
      stroke_id: @whiteboard.whiteboard_strokes.last.id,
      client_id: "test-client-id"
    })
  end

  test "clear action destroys all strokes and broadcasts" do
    @whiteboard.whiteboard_strokes.create!(user: @owner, stroke_data: { "points" => [ [ 0, 0 ] ] })
    stub_connection(current_user: @owner)
    subscribe(whiteboard_id: @whiteboard.id)

    assert_difference -> { @whiteboard.whiteboard_strokes.count }, -1 do
      perform :clear
    end

    assert_broadcast_on(@whiteboard, { type: "clear" })
  end

  test "non-owner cannot clear" do
    @whiteboard.add_collaborator(@collaborator)
    @whiteboard.whiteboard_strokes.create!(user: @owner, stroke_data: { "points" => [ [ 0, 0 ] ] })
    stub_connection(current_user: @collaborator)
    subscribe(whiteboard_id: @whiteboard.id)

    assert_no_difference -> { @whiteboard.whiteboard_strokes.count } do
      perform :clear
    end
  end

  test "delete action destroys strokes and broadcasts" do
    stroke1 = @whiteboard.whiteboard_strokes.create!(user: @owner, stroke_data: { "shape" => "rect", "x" => 0, "y" => 0, "w" => 10, "h" => 10 })
    stroke2 = @whiteboard.whiteboard_strokes.create!(user: @owner, stroke_data: { "shape" => "circle", "x" => 5, "y" => 5, "w" => 10, "h" => 10 })
    stub_connection(current_user: @owner)
    subscribe(whiteboard_id: @whiteboard.id)

    assert_difference -> { @whiteboard.whiteboard_strokes.count }, -2 do
      perform :delete, stroke_ids: [ stroke1.id, stroke2.id ]
    end

    assert_broadcast_on(@whiteboard, { type: "delete", stroke_ids: [ stroke1.id, stroke2.id ] })
  end

  test "collaborator can delete own strokes" do
    @whiteboard.add_collaborator(@collaborator)
    stroke = @whiteboard.whiteboard_strokes.create!(user: @collaborator, stroke_data: { "points" => [ [ 0, 0 ] ] })
    stub_connection(current_user: @collaborator)
    subscribe(whiteboard_id: @whiteboard.id)

    assert_difference -> { @whiteboard.whiteboard_strokes.count }, -1 do
      perform :delete, stroke_ids: [ stroke.id ]
    end
  end

  test "collaborator cannot delete owner strokes" do
    @whiteboard.add_collaborator(@collaborator)
    stroke = @whiteboard.whiteboard_strokes.create!(user: @owner, stroke_data: { "points" => [ [ 0, 0 ] ] })
    stub_connection(current_user: @collaborator)
    subscribe(whiteboard_id: @whiteboard.id)

    assert_no_difference -> { @whiteboard.whiteboard_strokes.count } do
      perform :delete, stroke_ids: [ stroke.id ]
    end
  end
end
