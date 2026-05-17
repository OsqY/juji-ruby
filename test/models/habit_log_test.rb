require "test_helper"

class HabitLogTest < ActiveSupport::TestCase
  test "belongs to habit" do
    log = habit_logs(:one)
    assert log.habit.present?
  end

  test "validates uniqueness of log_date per habit" do
    existing = habit_logs(:one)
    log = HabitLog.new(habit: existing.habit, log_date: existing.log_date)
    assert_not log.valid?
  end

  test "validates log_date presence" do
    log = HabitLog.new(log_date: nil)
    assert_not log.valid?
    assert_includes log.errors[:log_date], "no puede estar en blanco"
  end
end
