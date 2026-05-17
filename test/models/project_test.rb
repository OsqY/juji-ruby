require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "belongs to user" do
    project = projects(:one)
    assert project.user.present?
  end

  test "has many project_tasks" do
    project = projects(:one)
    assert_respond_to project, :project_tasks
  end

  test "validates name presence" do
    project = Project.new(name: nil)
    assert_not project.valid?
    assert_includes project.errors[:name], "no puede estar en blanco"
  end

  test "destroys dependent project_tasks" do
    project = projects(:one)
    tasks_count = project.project_tasks.count
    assert tasks_count > 0
    
    assert_difference("ProjectTask.count", -tasks_count) do
      project.destroy
    end
  end
end
