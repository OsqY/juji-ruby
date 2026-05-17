class AnalyticsService
  def self.spending_by_month(user, months: 12)
    end_date = Time.zone.today
    start_date = end_date - months.months
    
    data = {}
    months.times do |i|
      date = start_date + i.months
      month_start = date.beginning_of_month
      month_end = date.end_of_month
      
      amount = user.transactions
        .where("date BETWEEN ? AND ?", month_start, month_end)
        .sum(:amount)
      
      key = date.strftime("%b %Y")
      data[key] = amount.round(2)
    end
    
    data
  end

  def self.spending_by_category(user, limit: 5)
    user.transactions
      .group(:category)
      .sum(:amount)
      .sort_by { |_, v| -v }
      .take(limit)
      .to_h
      .transform_values { |v| v.round(2) }
  end

  def self.habit_completion_rate(user, months: 12)
    end_date = Time.zone.today
    start_date = end_date - months.months
    
    # Pre-cargar todos los logs en un solo query y agrupar por mes en Ruby
    all_logs = HabitLog
      .joins(:habit)
      .where(habits: { user_id: user.id })
      .where("log_date BETWEEN ? AND ?", start_date, end_date)
      .select(:log_date, :completed)
    
    # Agrupar por mes
    logs_by_month = {}
    all_logs.each do |log|
      month_key = log.log_date.beginning_of_month
      logs_by_month[month_key] ||= { total: 0, completed: 0 }
      logs_by_month[month_key][:total] += 1
      logs_by_month[month_key][:completed] += 1 if log.completed
    end
    
    data = {}
    months.times do |i|
      date = start_date + i.months
      month_start = date.beginning_of_month
      
      stats = logs_by_month[month_start] || { total: 0, completed: 0 }
      rate = stats[:total] > 0 ? (stats[:completed].to_f / stats[:total] * 100).round(1) : 0
      
      key = date.strftime("%b %Y")
      data[key] = rate
    end
    
    data
  end

  def self.project_status(user)
    all_projects = user.projects.includes(:project_tasks)
    
    {
      active: all_projects.count { |p| p.target_date.blank? || p.target_date > Time.zone.today },
      completed: all_projects.count { |p| p.project_tasks.any? && p.project_tasks.all?(&:completed) },
      overdue: all_projects.count { |p| p.target_date.present? && p.target_date < Time.zone.today }
    }
  end

  def self.alerts_trend(user, months: 12)
    end_date = Time.zone.today
    start_date = end_date - months.months
    
    data = {}
    months.times do |i|
      date = start_date + i.months
      month_start = date.beginning_of_month
      month_end = date.end_of_month
      
      alerts = user.notifications
        .where("created_at BETWEEN ? AND ?", month_start, month_end)
        .count
      
      key = date.strftime("%b %Y")
      data[key] = alerts
    end
    
    data
  end

  def self.weekly_balance(user, weeks: 12)
    data = {}
    weeks.times do |i|
      week_start = (Time.zone.today - weeks.weeks) + (i * 1.week)
      week_end = week_start + 6.days
      
      income = user.transactions
        .where("date BETWEEN ? AND ?", week_start, week_end)
        .where(transaction_type: "income")
        .sum(:amount)
      
      expenses = user.transactions
        .where("date BETWEEN ? AND ?", week_start, week_end)
        .where(transaction_type: "expense")
        .sum(:amount)
      
      balance = (income - expenses).round(2)
      key = week_start.strftime("W%W %Y")
      data[key] = balance
    end
    
    data
  end

  def self.project_progress(user)
    projects = user.projects.includes(:project_tasks).map do |project|
      total_tasks = project.project_tasks.size
      completed_tasks = project.project_tasks.count(&:completed)
      progress = total_tasks > 0 ? (completed_tasks.to_f / total_tasks * 100).round(1) : 0
      
      {
        name: project.name,
        progress: progress,
        completed: completed_tasks,
        total: total_tasks
      }
    end
    
    projects.sort_by { |p| -p[:progress] }
  end

  def self.expense_summary(user, days: 30)
    start_date = Time.zone.today - days.days
    
    total = user.transactions
      .where("date >= ?", start_date)
      .where(transaction_type: "expense")
      .sum(:amount)
    
    by_category = user.transactions
      .where("date >= ?", start_date)
      .where(transaction_type: "expense")
      .group(:category)
      .sum(:amount)
      .transform_values { |v| v.round(2) }
    
    {
      total: total.round(2),
      by_category: by_category,
      days: days
    }
  end
end
