require "test_helper"

class MonthlyGoalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
    @monthly_goal = monthly_goals(:one)
  end

  private
    def sign_in_as(user)
      post session_path, params: { email_address: user.email_address, password: "password" }
    end

  test "should get index" do
    get monthly_goals_url
    assert_response :success
  end

  test "should get new" do
    get new_monthly_goal_url
    assert_response :success
  end

  test "should create monthly_goal" do
    assert_difference("MonthlyGoal.count") do
      post monthly_goals_url, params: { monthly_goal: { title: "Nueva meta", description: "Desc", goal_type: "savings", target_value: 100, category: "finanzas" } }
    end

    assert_redirected_to monthly_goals_url
  end

  test "should get edit" do
    get edit_monthly_goal_url(@monthly_goal)
    assert_response :success
  end

  test "should update monthly_goal" do
    patch monthly_goal_url(@monthly_goal), params: { monthly_goal: { title: "Meta actualizada" } }
    assert_redirected_to monthly_goals_url
  end

  test "should destroy monthly_goal" do
    assert_difference("MonthlyGoal.count", -1) do
      delete monthly_goal_url(@monthly_goal)
    end

    assert_redirected_to monthly_goals_url
  end
end
