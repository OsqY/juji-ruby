require "test_helper"

class TurboUxSmokeTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)

    @habit = habits(:one)
    @shopping_item = shopping_items(:one)
    @project = projects(:one)
    @project_task = project_tasks(:one)

    @transaction = @user.transactions.create!(
      amount: 50,
      description: "Compra QA",
      transaction_type: :expense,
      category: "varios",
      date: Date.current
    )

    @budget = @user.budgets.create!(
      category: "qa",
      month: Date.current.beginning_of_month,
      monthly_limit: 100
    )

    @daily_report = @user.daily_reports.create!(
      report_date: Date.current,
      work_title: "Reporte QA",
      worked_by: "QA",
      yesterday: "avance",
      today: "validacion",
      blockers: "Bloqueo inicial"
    )
  end

  test "habits create returns turbo replacement with inline flash" do
    post habits_path,
      params: { habit: { name: "Lectura" } },
      headers: turbo_headers

    assert_response :success
    assert_turbo_replace("habits_content")
    assert_match(/HABIT CREATED/i, @response.body)
  end

  test "shopping items invalid create returns turbo 422 with inline flash" do
    post shopping_items_path,
      params: { shopping_item: { name: "", quantity: "1" } },
      headers: turbo_headers

    assert_response :unprocessable_entity
    assert_turbo_replace("shopping_items_content")
    assert_match(/NO PUEDE ESTAR EN BLANCO|CAN'T BE BLANK/i, @response.body)
  end

  test "project task toggle returns turbo replacement and notice" do
    post toggle_project_project_task_path(@project, @project_task), headers: turbo_headers

    assert_response :success
    assert_turbo_replace("projects_content")
    assert_match(/LOGRO ACTUALIZADO/i, @response.body)
  end

  test "budget create in transactions context replaces transactions frame" do
    post budgets_path(context: "transactions"),
      params: {
        budget: {
          category: "hogar",
          month: Date.current.beginning_of_month.strftime("%Y-%m-%d"),
          monthly_limit: 300
        }
      },
      headers: turbo_headers

    assert_response :success
    assert_turbo_replace("transactions_content")
    assert_match(/PRESUPUESTO GUARDADO/i, @response.body)
  end

  test "budget destroy in budgets context replaces budgets frame" do
    delete budget_path(@budget, context: "budgets"), headers: turbo_headers

    assert_response :success
    assert_turbo_replace("budgets_content")
    assert_match(/PRESUPUESTO ELIMINADO/i, @response.body)
  end

  test "transaction destroy returns turbo replacement and notice" do
    delete transaction_path(@transaction, month: Date.current.strftime("%Y-%m")), headers: turbo_headers

    assert_response :success
    assert_turbo_replace("transactions_content")
    assert_match(/TRANSACCION ELIMINADA/i, @response.body)
  end

  test "daily report blocker toggle returns turbo replacement and notice" do
    patch toggle_blocker_daily_report_path(@daily_report),
      params: {
        resolved: "1",
        view: "week",
        date: Date.current.strftime("%Y-%m-%d")
      },
      headers: turbo_headers

    assert_response :success
    assert_turbo_replace("daily_reports_content")
    assert_match(/BLOQUEO MARCADO COMO RESUELTO/i, @response.body)
  end

  private
    def turbo_headers
      { "Accept" => Mime[:turbo_stream].to_s }
    end

    def assert_turbo_replace(target)
      assert_equal Mime[:turbo_stream].to_s, @response.media_type
      assert_match(%r{<turbo-stream action="replace" target="#{target}">}, @response.body)
    end
end