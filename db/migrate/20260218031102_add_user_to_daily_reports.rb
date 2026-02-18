class AddUserToDailyReports < ActiveRecord::Migration[8.1]
  def change
    add_reference :daily_reports, :user, null: true, foreign_key: true
  end
end
