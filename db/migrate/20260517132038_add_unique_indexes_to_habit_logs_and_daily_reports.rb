class AddUniqueIndexesToHabitLogsAndDailyReports < ActiveRecord::Migration[8.1]
  def change
    add_index :habit_logs, [:habit_id, :log_date], unique: true
    add_index :daily_reports, [:user_id, :report_date], unique: true
  end
end
