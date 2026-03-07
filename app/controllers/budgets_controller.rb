class BudgetsController < ApplicationController
  before_action :set_budget, only: :destroy

  def index
    @selected_month = parse_month
    @budgets = current_user.budgets.for_month(@selected_month).order(:category)
    @previous_month = @selected_month.prev_month
    @next_month = @selected_month.next_month
  end

  def create
    @budget = current_user.budgets.new(budget_params)

    if @budget.save
      redirect_to transactions_path(month: @budget.month.strftime("%Y-%m")), notice: "Presupuesto guardado."
    else
      redirect_to transactions_path(month: selected_month.strftime("%Y-%m")), alert: @budget.errors.full_messages.to_sentence
    end
  end

  def destroy
    month = @budget.month
    @budget.destroy

    redirect_to transactions_path(month: month.strftime("%Y-%m")), notice: "Presupuesto eliminado.", status: :see_other
  end

  private
    def set_budget
      @budget = current_user.budgets.find(params[:id])
    end

    def budget_params
      params.expect(budget: [ :category, :month, :monthly_limit ])
    end

    def selected_month
      Date.strptime(params[:budget][:month], "%Y-%m-%d")
    rescue StandardError
      Date.current.beginning_of_month
    end

    def parse_month
      return Date.strptime(params[:month], "%Y-%m") if params[:month].present?

      Date.current.beginning_of_month
    rescue ArgumentError
      Date.current.beginning_of_month
    end
end
