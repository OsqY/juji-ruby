class CheckAlertsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting alert checks for all users..."
    
    alert_count = AlertService.check_all_users
    
    Rails.logger.info "Completed alert checks. Total alerts created/updated: #{alert_count}"
    
    alert_count
  end
end
