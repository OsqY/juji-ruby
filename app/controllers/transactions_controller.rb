class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[ destroy ]

  def index
    load_index_data(parse_month)
  end

  def new
    @transaction = current_user.transactions.new
    load_category_options
  end

  def create
    @transaction = current_user.transactions.new(transaction_params)
    @transaction.category = resolved_category_param(:transaction)

    if @transaction.save
      month_date = @transaction.date.beginning_of_month

      if turbo_frame_request?
        load_index_data(month_date)
        flash.now[:notice] = I18n.t("transactions.flash.created")
        render turbo_stream: [
          turbo_stream.replace("transactions_content", partial: "transactions/content"),
          turbo_stream.replace("transaction_form_panel", partial: "shared/empty_frame", locals: { frame_id: "transaction_form_panel" })
        ]
      else
        redirect_to transactions_path(month: month_date.strftime("%Y-%m")), notice: I18n.t("transactions.flash.created")
      end
    else
      load_category_options
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
        flash.now[:notice] = I18n.t("transactions.flash.deleted")
        render_transactions_content
      end
      format.html { redirect_to transactions_path(month: month_date.strftime("%Y-%m")), notice: I18n.t("transactions.flash.deleted"), status: :see_other }
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
      @category_options = category_options_for_user
    end

    def load_category_options
      @category_options = category_options_for_user
    end

    def category_options_for_user
      transaction_categories = current_user.transactions.where.not(category: [ nil, "" ]).pluck(:category)
      budget_categories = current_user.budgets.where.not(category: [ nil, "" ]).pluck(:category)

      (transaction_categories + budget_categories)
        .map { |category| category.to_s.strip.downcase }
        .reject(&:blank?)
        .uniq
        .sort
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

    def resolved_category_param(scope)
      input = params[scope] || {}
      custom = input[:category_custom].to_s.strip
      option = input[:category_option].to_s.strip

      return custom if custom.present?
      return "" if option == "__new__"
      return option if option.present?

      input[:category].to_s
    end
end
