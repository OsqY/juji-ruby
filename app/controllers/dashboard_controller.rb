class DashboardController < ApplicationController
  def index
    @latest_daily = current_user.daily_reports.order(report_date: :desc).first
    @open_blockers = current_user.daily_reports
      .where.not(blockers: [ nil, "" ])
      .where(blockers_resolved: false)
      .order(report_date: :desc)
      .limit(6)

    month_range = Date.current.beginning_of_month..Date.current.end_of_month
    month_transactions = current_user.transactions.where(date: month_range)

    @month_income = month_transactions.income.sum(:amount)
    @month_expenses = month_transactions.expense.sum(:amount)
    @month_balance = @month_income - @month_expenses

    raw_category_expenses = month_transactions.expense.group(:category).sum(:amount)
    @expenses_by_category = raw_category_expenses.transform_keys do |category|
      category.present? ? category : "varios"
    end.sort_by { |_, amount| -amount }
  end
end
