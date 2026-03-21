require "test_helper"

class ExportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "exports transactions csv" do
    post exports_path, params: { model: "transactions", format: "csv" }

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.headers["Content-Disposition"], "transactions_"
  end

  test "exports transactions pdf" do
    post exports_path, params: { model: "transactions", format: "pdf" }

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_includes response.headers["Content-Disposition"], "transactions_"
  end

  test "rejects invalid model" do
    post exports_path, params: { model: "invalid", format: "csv" }

    assert_response :unprocessable_entity
  end

  test "rejects invalid format" do
    post exports_path, params: { model: "transactions", format: "zip" }

    assert_response :unprocessable_entity
  end
end
