require "test_helper"

class WhiteboardCollaboratorTest < ActiveSupport::TestCase
  setup do
    @owner = users(:one)
    @collaborator = users(:two)
    @whiteboard = @owner.whiteboards.create!(name: "Shared Board")
  end

  test "valid collaborator" do
    wc = @whiteboard.whiteboard_collaborators.new(user: @collaborator)
    assert wc.valid?
    assert wc.save
  end

  test "user cannot be collaborator twice" do
    @whiteboard.whiteboard_collaborators.create!(user: @collaborator)
    wc = @whiteboard.whiteboard_collaborators.new(user: @collaborator)
    assert_not wc.valid?
  end
end
