class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[ destroy ]

  def index
    load_index_data(parse_month)
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

    month_date = begin
      Date.strptime(month, "%Y-%m").beginning_of_month
    rescue ArgumentError
      @transaction.date.beginning_of_month
    end

    load_index_data(month_date)

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Transaccion eliminada."
        render_transactions_content
      end
      format.html { redirect_to transactions_path(month: month_date.strftime("%Y-%m")), notice: "Eliminado.", status: :see_other }
    end
  end

  private
    def load_index_data(month)
      @selected_month = month.beginning_of_month
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

    def render_transactions_content(status: :ok)
      render turbo_stream: turbo_stream.replace("transactions_content", partial: "transactions/content"), status: status
    end

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
