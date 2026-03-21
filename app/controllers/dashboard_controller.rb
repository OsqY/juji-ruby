class DashboardController < ApplicationController
  def index
    week_range = Date.current.beginning_of_week..Date.current.end_of_week

    @latest_daily = current_user.daily_reports.order(report_date: :desc).first
    @open_blockers = current_user.daily_reports
      .where.not(blockers: [ nil, "" ])
      .where(blockers_resolved: false)
      .order(report_date: :desc)
      .limit(6)

    @weekly_reports_count = current_user.daily_reports.where(report_date: week_range).count
    @weekly_open_blockers_count = current_user.daily_reports
      .where(report_date: week_range)
      .where.not(blockers: [ nil, "" ])
      .where(blockers_resolved: false)
      .count

    week_transactions = current_user.transactions.where(date: week_range)
    @week_income = week_transactions.income.sum(:amount)
    @week_expenses = week_transactions.expense.sum(:amount)
    @week_balance = @week_income - @week_expenses

    @weekly_habits_completed = HabitLog
      .joins(:habit)
      .where(habits: { user_id: current_user.id })
      .where(log_date: week_range, completed: true)
      .count

    @weekly_tasks_completed = ProjectTask
      .joins(:project)
      .where(projects: { user_id: current_user.id }, completed: true)
      .where(updated_at: week_range)
      .count

    month_range = Date.current.beginning_of_month..Date.current.end_of_month
    month_transactions = current_user.transactions.where(date: month_range)

    @month_income = month_transactions.income.sum(:amount)
    @month_expenses = month_transactions.expense.sum(:amount)
    @month_balance = @month_income - @month_expenses

    raw_category_expenses = month_transactions.expense.group(:category).sum(:amount)
    @expenses_by_category = raw_category_expenses.transform_keys do |category|
      category.present? ? category : "varios"
    end.sort_by { |_, amount| -amount }

    @month_budget_total = current_user.budgets.for_month(Date.current).sum(:monthly_limit)
    @month_budget_usage_percent = if @month_budget_total.to_f.positive?
      ((@month_expenses.to_f / @month_budget_total.to_f) * 100).round(1)
    else
      0
    end

    @alerts = []

    if @month_budget_total.to_f.positive? && @month_expenses.to_f > @month_budget_total.to_f
      overflow = @month_expenses.to_f - @month_budget_total.to_f
      @alerts << {
        level: :danger,
        title: "Presupuesto superado",
        message: "Te excediste L. #{format('%.2f', overflow)} en el mes actual."
      }
    end

    latest_report_date = current_user.daily_reports.maximum(:report_date)
    if latest_report_date.nil? || latest_report_date < Date.current - 2.days
      days_without_report = latest_report_date.nil? ? ">= 3" : (Date.current - latest_report_date).to_i
      @alerts << {
        level: :warning,
        title: "Sin reporte diario reciente",
        message: "Llevas #{days_without_report} dias sin registrar reporte."
      }
    end

    stale_projects = current_user.projects.includes(:project_tasks).select do |project|
      last_task_update = project.project_tasks.maximum(:updated_at)
      last_task_update.nil? || last_task_update < 7.days.ago
    end

    if stale_projects.any?
      project_names = stale_projects.first(3).map(&:name).join(", ")
      more = stale_projects.size > 3 ? " y #{stale_projects.size - 3} mas" : ""
      @alerts << {
        level: :warning,
        title: "Proyectos sin avances",
        message: "Sin actividad reciente en: #{project_names}#{more}."
      }
    end

    @unread_notifications_count = current_user.notifications.unread.count
    
    load_weekly_indicators
  end

  private

  def load_weekly_indicators
    week_range = Date.current.beginning_of_week..Date.current.end_of_week
    month_range = Date.current.beginning_of_month..Date.current.end_of_month

    # 1. Hábitos cumplidos esta semana
    @indicator_habits_completed = HabitLog
      .joins(:habit)
      .where(habits: { user_id: current_user.id })
      .where(log_date: week_range, completed: true)
      .count

    @indicator_habits_total = current_user.habits.count

    # 2. Gasto vs Presupuesto (mes actual)
    @indicator_month_expenses = current_user.transactions
      .where(date: month_range, transaction_type: :expense)
      .sum(:amount)

    @indicator_month_budget = current_user.budgets.for_month(Date.current).sum(:monthly_limit)

    @indicator_budget_percent = if @indicator_month_budget.to_f.positive?
      ((@indicator_month_expenses.to_f / @indicator_month_budget.to_f) * 100).round(1)
    else
      0
    end

    # 3. Tareas cerradas esta semana
    @indicator_tasks_completed = ProjectTask
      .joins(:project)
      .where(projects: { user_id: current_user.id }, completed: true)
      .where(updated_at: week_range)
      .count

    # 4. Bloqueos abiertos (sin límite de fecha)
    @indicator_open_blockers = current_user.daily_reports
      .where.not(blockers: [ nil, "" ])
      .where(blockers_resolved: false)
      .count

    # 5. Reportes enviados esta semana
    @indicator_reports_sent = current_user.daily_reports.where(report_date: week_range).count
    @indicator_reports_target = 5 # días de trabajo

    # 6. Balance semanal
    week_transactions = current_user.transactions.where(date: week_range)
    week_income = week_transactions.where(transaction_type: :income).sum(:amount)
    week_expenses = week_transactions.where(transaction_type: :expense).sum(:amount)
    @indicator_weekly_balance = week_income - week_expenses
  end
end
