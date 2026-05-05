require "test_helper"

class WhiteboardStrokeTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @whiteboard = @user.whiteboards.create!(name: "Test Board")
  end

  test "valid stroke" do
    stroke = @whiteboard.whiteboard_strokes.new(
      user: @user,
      stroke_data: { "tool" => "pen", "color" => "#000", "width" => 3, "points" => [[0, 0], [10, 10]] }
    )
    assert stroke.valid?
    assert stroke.save
  end

  test "stroke_data is required" do
    stroke = @whiteboard.whiteboard_strokes.new(user: @user)
    assert_not stroke.valid?
    assert_includes stroke.errors[:stroke_data], "no puede estar en blanco"
  end
end
