require "test_helper"

class HabitTest < ActiveSupport::TestCase
  test "validates name presence" do
    habit = Habit.new(name: nil)
    assert_not habit.valid?
    assert_includes habit.errors[:name], "no puede estar en blanco"
  end

  test "belongs to user" do
    habit = habits(:one)
    assert habit.user.present?
  end

  test "has many habit_logs" do
    habit = habits(:one)
    assert_respond_to habit, :habit_logs
  end
end
