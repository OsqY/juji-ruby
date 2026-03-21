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
    
    data = {}
    months.times do |i|
      date = start_date + i.months
      month_start = date.beginning_of_month
      month_end = date.end_of_month
      
      logs = user.habits.flat_map do |habit|
        habit.habit_logs.where("log_date BETWEEN ? AND ?", month_start, month_end)
      end
      
      if logs.any?
        completed = logs.count { |log| log.completed }
        rate = (completed.to_f / logs.count * 100).round(1)
      else
        rate = 0
      end
      
      key = date.strftime("%b %Y")
      data[key] = rate
    end
    
    data
  end

  def self.project_status(user)
    all_projects = user.projects
    
    {
      active: all_projects.select { |p| p.target_date.blank? || p.target_date > Time.zone.today }.count,
      completed: all_projects.count { |p| p.project_tasks.all? { |t| t.completed } },
      overdue: all_projects.select { |p| p.target_date.present? && p.target_date < Time.zone.today }.count
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
    projects = user.projects.map do |project|
      total_tasks = project.project_tasks.count
      completed_tasks = project.project_tasks.where(completed: true).count
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
