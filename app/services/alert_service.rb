class AlertService
  def self.check_all_users
    alerts_count = 0
    User.find_each { |user| alerts_count += check_for_user(user).count }
    alerts_count
  end

  def self.check_for_user(user)
    alerts = []
    
    budget_alert = check_budget_exceeded(user)
    alerts << budget_alert if budget_alert
    
    report_alert = check_no_reports_3_days(user)
    alerts << report_alert if report_alert
    
    progress_alert = check_project_no_progress(user)
    alerts << progress_alert if progress_alert
    
    # Create notifications in DB
    alerts.each { |alert| create_notification(user, alert[:type], alert[:message]) }
    
    alerts
  end

  def self.check_budget_exceeded(user)
    current_month = Time.zone.today.beginning_of_month

    user.budgets.where(month: current_month).each do |budget|
      total_spent = user.transactions
        .where(category: budget.category)
        .where("date BETWEEN ? AND ?", current_month, current_month.end_of_month)
        .sum(:amount)

      if total_spent > budget.monthly_limit
        overage = total_spent - budget.monthly_limit
        return {
          type: :budget_exceeded,
          level: :danger,
          title: "Presupuesto superado",
          message: "Has gastado L. #{format('%.2f', total_spent)} en #{budget.category}, superando el límite de L. #{format('%.2f', budget.monthly_limit)} por L. #{format('%.2f', overage)}"
        }
      end
    end
    
    nil
  end

  def self.check_no_reports_3_days(user)
    last_report_date = user.daily_reports.order(report_date: :desc).pick(:report_date)
    days_threshold = AlertsConfig::DAYS_WITHOUT_REPORT
    
    if last_report_date.nil?
      days_elapsed = days_threshold
      {
        type: :no_report_3_days,
        level: :warning,
        title: "Sin reportes recientes",
        message: "No has enviado reporte diario. Días transcurridos >= #{days_elapsed}"
      }
    elsif (Time.zone.today - last_report_date).to_i >= days_threshold
      days_elapsed = (Time.zone.today - last_report_date).to_i
      {
        type: :no_report_3_days,
        level: :warning,
        title: "Sin reportes recientes",
        message: "No has enviado reporte diario en #{days_elapsed} días (>= #{days_threshold}). ¡Actualiza tu estado!"
      }
    else
      nil
    end
  end

  def self.check_project_no_progress(user)
    days_threshold = AlertsConfig::DAYS_PROJECT_NO_PROGRESS
    stale_projects = []
    
    # Check all projects for staleness
    user.projects.each do |project|
      last_task = project.project_tasks.order(updated_at: :desc).first
      
      if last_task.nil? || (Time.zone.today - last_task.updated_at.to_date).to_i >= days_threshold
        stale_projects << project
      end
    end
    
    if stale_projects.empty?
      nil
    elsif stale_projects.length == 1
      {
        type: :project_no_progress,
        level: :warning,
        title: "Proyecto sin avances",
        message: "Proyecto '#{stale_projects[0].name}' sin actividad hace más de #{days_threshold} días"
      }
    else
      # Multiple stale projects - show first 3, mention the rest
      to_display = stale_projects[0..2]
      displayed = to_display.map { |p| p.name }.join(" y ")
      remaining = stale_projects.length - 3
      message = "Proyectos '#{displayed}'"
      message += " y #{remaining} mas" if remaining > 0
      message += " sin avances hace más de #{days_threshold} días"
      
      {
        type: :project_no_progress,
        level: :warning,
        title: "Proyectos sin avances",
        message: message
      }
    end
  end

  private

  def self.create_notification(user, type, message)
    user.notifications.find_or_create_by(
      notification_type: type
    ) do |notification|
      notification.message = message
      notification.read_at = nil
    end
  end
end
