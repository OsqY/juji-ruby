class AlertService
  def self.check_all_users
    User.find_each { |user| check_for_user(user) }
  end

  def self.check_for_user(user)
    check_budget_exceeded(user)
    check_no_reports_3_days(user)
    check_project_no_progress(user)
  end

  private

  def self.check_budget_exceeded(user)
    current_month = Time.zone.today.month
    current_year = Time.zone.today.year

    user.budgets.each do |budget|
      next unless budget.month == current_month

      total_spent = user.transactions
        .where(category: budget.category)
        .where("EXTRACT(MONTH FROM date) = ? AND EXTRACT(YEAR FROM date) = ?", current_month, current_year)
        .sum(:amount)

      if total_spent > budget.monthly_limit
        create_notification(
          user,
          :budget_exceeded,
          "Presupuesto de #{budget.category} superado: #{total_spent} > #{budget.monthly_limit}"
        )
      end
    end
  end

  def self.check_no_reports_3_days(user)
    last_report_date = user.daily_reports.order(report_date: :desc).pick(:report_date)
    days_threshold = AlertsConfig::DAYS_WITHOUT_REPORT
    
    if last_report_date.nil? || (Time.zone.today - last_report_date).to_i >= days_threshold
      create_notification(
        user,
        :no_report_3_days,
        "No has enviado reporte diario en #{days_threshold} días. ¡Actualiza tu estado!"
      )
    end
  end

  def self.check_project_no_progress(user)
    days_threshold = AlertsConfig::DAYS_PROJECT_NO_PROGRESS
    
    user.projects.each do |project|
      last_task = project.project_tasks.order(created_at: :desc).first
      
      if last_task.nil? || (Time.zone.today - last_task.created_at.to_date).to_i >= days_threshold
        create_notification(
          user,
          :project_no_progress,
          "Proyecto '#{project.name}' sin avances hace más de #{days_threshold} días"
        )
      end
    end
  end

  def self.create_notification(user, type, message)
    user.notifications.find_or_create_by(
      notification_type: type
    ) do |notification|
      notification.message = message
      notification.read_at = nil
    end
  end
end
