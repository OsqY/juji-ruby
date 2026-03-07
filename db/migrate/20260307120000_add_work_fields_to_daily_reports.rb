class AddWorkFieldsToDailyReports < ActiveRecord::Migration[8.1]
  def change
    add_column :daily_reports, :work_title, :string
    add_column :daily_reports, :worked_by, :string
  end
end
