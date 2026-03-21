require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "results responds successfully for shopping quantity query" do
    @user.shopping_items.create!(name: "Pan", quantity: "2 unidades")

    get search_results_path, params: { q: "2" }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body.key?("results")
    assert body.key?("total_count")
  end
end
