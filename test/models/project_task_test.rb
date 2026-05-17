require "test_helper"

class ProjectTaskTest < ActiveSupport::TestCase
  test "belongs to project" do
    task = project_tasks(:one)
    assert task.project.present?
  end

  test "validates name presence" do
    task = ProjectTask.new(name: nil)
    assert_not task.valid?
    assert_includes task.errors[:name], "no puede estar en blanco"
  end

  test "toggle completed status" do
    task = project_tasks(:one)
    original = task.completed
    task.update!(completed: !original)
    assert_not_equal original, task.reload.completed
  end
end
