class InsightService
  def self.generate_weekly_insights(user)
    week_start = Date.current.beginning_of_week
    week_end = Date.current.end_of_week

    insights = []

    # Financial insight
    expenses = user.transactions.where(date: week_start..week_end, transaction_type: :expense).sum(:amount)
    budgets = user.budgets.where(month: Date.current.beginning_of_month)
    budgets.each do |budget|
      spent = user.transactions.where(category: budget.category, transaction_type: :expense, date: week_start..week_end).sum(:amount)
      if spent > budget.monthly_limit / 4
        insights << "Gastaste L. #{spent} en #{budget.category} esta semana. El presupuesto mensual es L. #{budget.monthly_limit}."
      end
    end

    # Productivity insight
    reports_count = user.daily_reports.where(report_date: week_start..week_end).count
    if reports_count >= 5
      insights << "Excelente semana de reportes: enviaste #{reports_count} reportes."
    elsif reports_count < 3
      insights << "Envía al menos 3 reportes semanales para mantener el seguimiento."
    end

    # Habit insight
    habit_rate = calculate_weekly_habit_rate(user, week_start, week_end)
    if habit_rate >= 80
      insights << "Tus hábitos van muy bien esta semana (#{habit_rate}%)."
    end

    # Project insight
    stale_projects = user.projects.includes(:project_tasks).select do |project|
      last_task = project.project_tasks.maximum(:updated_at)
      last_task.nil? || last_task < 7.days.ago
    end
    if stale_projects.any?
      insights << "Tienes #{stale_projects.count} proyecto(s) sin avances recientes."
    end

    insights
  end

  def self.generate_monthly_insights(user)
    month_start = Date.current.beginning_of_month
    month_end = Date.current.end_of_month

    insights = []

    # Financial health
    income = user.transactions.where(date: month_start..month_end, transaction_type: :income).sum(:amount)
    expenses = user.transactions.where(date: month_start..month_end, transaction_type: :expense).sum(:amount)
    savings_rate = income > 0 ? ((income - expenses) / income * 100).round(1) : 0

    if savings_rate >= 20
      insights << "¡Excelente tasa de ahorro! Ahorraste el #{savings_rate}% de tus ingresos."
    elsif savings_rate < 0
      insights << "Gastaste más de lo que ingresaste. Revisa tus presupuestos para el próximo mes."
    end

    # Goal tracking
    goals = user.monthly_goals.for_month(Date.current)
    completed = goals.select(&:completed?)
    active = goals.select(&:active?)

    if completed.any?
      insights << "Completaste #{completed.count} meta(s) este mes."
    end

    if active.any?
      insights << "Tienes #{active.count} meta(s) activa(s) para este mes."
    end

    # Streak analysis
    streaks = user.user_streaks.where("current_streak >= 7")
    if streaks.any?
      insights << "Mantienes #{streaks.count} racha(s) de 7+ días. ¡Gran consistencia!"
    end

    # Achievements
    new_achievements = user.user_achievements.unlocked_this_month
    if new_achievements.any?
      insights << "Desbloqueaste #{new_achievements.count} logro(s) nuevo(s) este mes."
    end

    insights
  end

  def self.create_insight_notification(user, insights)
    return if insights.empty?

    message = insights.first(3).join(" ")
    Notification.create!(
      user: user,
      notification_type: "insight",
      message: message
    )
  end

  private

  def self.calculate_weekly_habit_rate(user, start_date, end_date)
    total = HabitLog.joins(:habit).where(habits: { user_id: user.id }, log_date: start_date..end_date).count
    completed = HabitLog.joins(:habit).where(habits: { user_id: user.id }, log_date: start_date..end_date, completed: true).count
    return 0 if total.zero?
    (completed.to_f / total * 100).round(1)
  end
end
