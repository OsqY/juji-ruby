namespace :alerts do
  desc "Check all users for alerts"
  task check_all: :environment do
    puts "Checking alerts for all users..."
    count = AlertService.check_all_users
    puts "Alert check completed. Total alerts created: #{count}"
  end
end
