class NotificationMailer < ApplicationMailer
  default from: "Juji <notificaciones@juji.app>"

  def alert_summary(user)
    @user = user
    @alerts = user.notifications.unread.recent.limit(10)
    @alert_count = @alerts.count

    return if @alerts.empty?

    mail(
      to: user.email_address,
      subject: "Tienes #{@alert_count} alerta(s) pendiente(s) en Juji"
    )
  end

  def weekly_digest(user)
    @user = user
    @week_start = Date.current.beginning_of_week
    @week_end = Date.current.end_of_week

    @weekly_reports = user.daily_reports.where(report_date: @week_start..@week_end).count
    @weekly_expenses = user.transactions.where(date: @week_start..@week_end, transaction_type: :expense).sum(:amount)
    @weekly_habits = HabitLog.joins(:habit).where(habits: { user_id: user.id }, log_date: @week_start..@week_end, completed: true).count
    @completed_tasks = ProjectTask.joins(:project).where(projects: { user_id: user.id }, completed: true, updated_at: @week_start.beginning_of_day..@week_end.end_of_day).count

    @streaks = user.user_streaks.where("current_streak > 0")
    @goals = user.monthly_goals.current.active_goals

    mail(
      to: user.email_address,
      subject: "Tu resumen semanal de Juji"
    )
  end

  def monthly_insights(user)
    @user = user
    @month_start = Date.current.beginning_of_month
    @month_end = Date.current.end_of_month

    @monthly_income = user.transactions.where(date: @month_start..@month_end, transaction_type: :income).sum(:amount)
    @monthly_expenses = user.transactions.where(date: @month_start..@month_end, transaction_type: :expense).sum(:amount)
    @monthly_balance = @monthly_income - @monthly_expenses

    @top_expenses = user.transactions.where(date: @month_start..@month_end, transaction_type: :expense).group(:category).sum(:amount).sort_by { |_, v| -v }.first(5)
    @habit_rate = calculate_habit_rate(user, @month_start, @month_end)
    @project_progress = calculate_project_progress(user)
    @goals_status = user.monthly_goals.for_month(Date.current).map { |g| { title: g.title, progress: g.progress_percentage, status: g.status } }

    @insights = generate_insights

    mail(
      to: user.email_address,
      subject: "Tus insights de #{I18n.l(Date.current, format: '%B %Y')}"
    )
  end

  def goal_achieved(goal)
    @goal = goal
    @user = goal.user

    mail(
      to: @user.email_address,
      subject: "¡Meta alcanzada! 🎉 #{goal.title}"
    )
  end

  def streak_milestone(streak)
    @streak = streak
    @user = streak.user

    mail(
      to: @user.email_address,
      subject: "¡Racha de #{streak.current_streak} días! 🔥"
    )
  end

  private

  def calculate_habit_rate(user, start_date, end_date)
    total_logs = HabitLog.joins(:habit).where(habits: { user_id: user.id }, log_date: start_date..end_date).count
    completed_logs = HabitLog.joins(:habit).where(habits: { user_id: user.id }, log_date: start_date..end_date, completed: true).count
    return 0 if total_logs.zero?
    (completed_logs.to_f / total_logs * 100).round(1)
  end

  def calculate_project_progress(user)
    projects = user.projects.includes(:project_tasks)
    return [] if projects.empty?
    projects.map do |project|
      total = project.project_tasks.size
      completed = project.project_tasks.count(&:completed)
      progress = total > 0 ? (completed.to_f / total * 100).round(1) : 0
      { name: project.name, progress: progress }
    end
  end

  def generate_insights
    insights = []

    if @monthly_expenses > @monthly_income
      insights << "Gastaste más de lo que ingresaste este mes. Considera revisar tus presupuestos."
    elsif @monthly_balance > 0
      insights << "¡Buen trabajo! Tuviste un balance positivo de L. #{@monthly_balance.round(2)} este mes."
    end

    if @habit_rate >= 80
      insights << "Excelente consistencia en tus hábitos (#{@habit_rate}%). ¡Sigue así!"
    elsif @habit_rate < 50
      insights << "Tus hábitos necesitan más atención. Intenta establecer recordatorios diarios."
    end

    completed_goals = @goals_status.select { |g| g[:status] == "completed" }
    if completed_goals.any?
      insights << "Completaste #{completed_goals.count} meta(s) este mes. ¡Felicitaciones!"
    end

    insights
  end
end
