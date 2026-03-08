class BudgetsController < ApplicationController
  before_action :set_budget, only: :destroy

  def index
    load_index_data
  end

  def create
    @budget = current_user.budgets.new(budget_params)
    @budget.category = resolved_category_param(:budget)
    month = selected_month.beginning_of_month

    if @budget.save
      load_transactions_context(month)

      respond_to do |format|
        format.turbo_stream do
          if transactions_context?
            flash.now[:notice] = "Presupuesto guardado."
            render_transactions_content
          elsif budgets_context?
            load_index_data(month)
            flash.now[:notice] = "Presupuesto guardado."
            render_budgets_content
          else
            redirect_to transactions_path(month: @budget.month.strftime("%Y-%m")), notice: "Presupuesto guardado."
          end
        end
        format.html { redirect_to transactions_path(month: @budget.month.strftime("%Y-%m")), notice: "Presupuesto guardado." }
      end
    else
      load_transactions_context(month, budget_form: @budget)

      respond_to do |format|
        format.turbo_stream do
          if transactions_context?
            flash.now[:alert] = @budget.errors.full_messages.to_sentence
            render_transactions_content(status: :unprocessable_entity)
          elsif budgets_context?
            load_index_data(month, budget_form: @budget)
            flash.now[:alert] = @budget.errors.full_messages.to_sentence
            render_budgets_content(status: :unprocessable_entity)
          else
            redirect_to transactions_path(month: month.strftime("%Y-%m")), alert: @budget.errors.full_messages.to_sentence
          end
        end
        format.html { redirect_to transactions_path(month: month.strftime("%Y-%m")), alert: @budget.errors.full_messages.to_sentence }
      end
    end
  end

  def destroy
    month = @budget.month.beginning_of_month
    @budget.destroy
    load_transactions_context(month)

    respond_to do |format|
      format.turbo_stream do
        if transactions_context?
          flash.now[:notice] = "Presupuesto eliminado."
          render_transactions_content
        elsif budgets_context?
          load_index_data(month)
          flash.now[:notice] = "Presupuesto eliminado."
          render_budgets_content
        else
          redirect_to transactions_path(month: month.strftime("%Y-%m")), notice: "Presupuesto eliminado.", status: :see_other
        end
      end
      format.html { redirect_to transactions_path(month: month.strftime("%Y-%m")), notice: "Presupuesto eliminado.", status: :see_other }
    end
  end

  private
    def load_index_data(month = parse_month, budget_form: nil)
      @selected_month = month.beginning_of_month
      month_range = @selected_month..@selected_month.end_of_month

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

      @budget = budget_form || current_user.budgets.new(month: @selected_month)
      @category_options = category_options_for_user
      @previous_month = @selected_month.prev_month
      @next_month = @selected_month.next_month
    end

    def load_transactions_context(month, budget_form: nil)
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

      @budget = budget_form || current_user.budgets.new(month: @selected_month)
      @previous_month = @selected_month.prev_month
      @next_month = @selected_month.next_month
      @category_options = category_options_for_user
    end

    def render_transactions_content(status: :ok)
      render turbo_stream: turbo_stream.replace("transactions_content", partial: "transactions/content"), status: status
    end

    def render_budgets_content(status: :ok)
      render turbo_stream: turbo_stream.replace("budgets_content", partial: "budgets/content"), status: status
    end

    def transactions_context?
      params[:context] == "transactions"
    end

    def budgets_context?
      params[:context] == "budgets"
    end

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

    def category_options_for_user
      transaction_categories = current_user.transactions.where.not(category: [ nil, "" ]).pluck(:category)
      budget_categories = current_user.budgets.where.not(category: [ nil, "" ]).pluck(:category)

      (transaction_categories + budget_categories)
        .map { |category| category.to_s.strip.downcase }
        .reject(&:blank?)
        .uniq
        .sort
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
