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
    assert body["results"].key?("shopping_items")
  end

  test "index ignores invalid date filters instead of failing" do
    get search_path, params: { q: "pan", from_date: "not-a-date", to_date: "2026-99-99" }

    assert_response :success
  end

  test "results returns machine keys expected by stimulus" do
    @user.habits.create!(name: "Leer")

    get search_results_path, params: { q: "leer" }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body["results"].key?("habits")
  end
end
