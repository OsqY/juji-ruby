class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[ destroy ]

  def index
    @selected_month = parse_month
    month_range = @selected_month..@selected_month.end_of_month

    @transactions = current_user.transactions.order(date: :desc)
    @month_transactions = current_user.transactions.where(date: month_range)
    @income = @month_transactions.income.sum(:amount)
    @expenses = @month_transactions.expense.sum(:amount)
    @balance = @income - @expenses

    grouped_expenses = @month_transactions.expense.group(:category).sum(:amount)
    @expenses_by_category = grouped_expenses.transform_keys { |category| category.presence || "varios" }

    @budgets = current_user.budgets.for_month(@selected_month).order(:category)
    @budget_rows = @budgets.map do |budget|
      spent = @expenses_by_category[budget.category] || 0
      percent = budget.monthly_limit.to_f.positive? ? ((spent.to_f / budget.monthly_limit.to_f) * 100).round(1) : 0
      status = percent >= 100 ? "danger" : (percent >= 80 ? "warning" : "ok")

      { budget:, spent:, percent:, status: }
    end

    @budget = current_user.budgets.new(month: @selected_month)
    @previous_month = @selected_month.prev_month
    @next_month = @selected_month.next_month
  end

  def new
    @transaction = current_user.transactions.new
  end

  def create
    @transaction = current_user.transactions.new(transaction_params)

    if @transaction.save
      redirect_to transactions_path(month: @transaction.date.beginning_of_month.strftime("%Y-%m")), notice: "Movimiento registrado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    month = params[:month].presence || @transaction.date.beginning_of_month.strftime("%Y-%m")
    @transaction.destroy
    redirect_to transactions_path(month: month), notice: "Eliminado.", status: :see_other
  end

  private
    def parse_month
      return Date.strptime(params[:month], "%Y-%m").beginning_of_month if params[:month].present?

      Date.current.beginning_of_month
    rescue ArgumentError
      Date.current.beginning_of_month
    end

    def set_transaction
      @transaction = current_user.transactions.find(params[:id])
    end

    def transaction_params
      params.expect(transaction: [ :amount, :description, :transaction_type, :category, :date ])
    end
end
