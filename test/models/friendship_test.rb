require "test_helper"

class FriendshipTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @other = users(:two)
  end

  test "valid friendship request" do
    f = Friendship.create!(requester: @user, addressee: @other)
    assert f.pending?
    assert f.invitation_token.present?
  end

  test "cannot friend self" do
    f = Friendship.new(requester: @user, addressee: @user)
    assert_not f.valid?
  end

  test "accept friendship" do
    f = Friendship.create!(requester: @user, addressee: @other)
    f.accept!
    assert f.accepted?
  end

  test "unique friendship" do
    Friendship.create!(requester: @user, addressee: @other)
    assert_raises(ActiveRecord::RecordInvalid) do
      Friendship.create!(requester: @user, addressee: @other)
    end
  end
end
