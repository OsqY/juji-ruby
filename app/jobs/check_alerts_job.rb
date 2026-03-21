class CheckAlertsJob < ApplicationJob
  queue_as :default

  def perform
    AlertService.check_all_users
  end
end
