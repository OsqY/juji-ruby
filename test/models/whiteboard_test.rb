require "test_helper"

class WhiteboardTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "valid whiteboard with defaults" do
    wb = @user.whiteboards.new(name: "Test Board")
    assert wb.valid?
    assert wb.save
    assert_equal 1200, wb.width
    assert_equal 800, wb.height
    assert_equal "#FFFFFF", wb.background_color
    assert wb.token.present?
  end

  test "token is unique" do
    wb1 = @user.whiteboards.create!(name: "Board 1")
    wb2 = @user.whiteboards.new(name: "Board 2", token: wb1.token)
    assert_not wb2.valid?
    assert_includes wb2.errors[:token], "ya está en uso"
  end

  test "name is required" do
    wb = @user.whiteboards.new
    assert_not wb.valid?
    assert_includes wb.errors[:name], "no puede estar en blanco"
  end

  test "collaborator? returns true for owner" do
    wb = @user.whiteboards.create!(name: "Owned")
    assert wb.collaborator?(@user)
  end

  test "collaborator? returns true for added collaborator" do
    wb = @user.whiteboards.create!(name: "Shared")
    other = users(:two)
    wb.add_collaborator(other)
    assert wb.collaborator?(other)
  end

  test "collaborator? returns false for unrelated user" do
    wb = @user.whiteboards.create!(name: "Private")
    other = users(:two)
    assert_not wb.collaborator?(other)
  end
end
