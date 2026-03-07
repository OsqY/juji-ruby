class AddBlockersResolvedToDailyReports < ActiveRecord::Migration[8.1]
  def change
    add_column :daily_reports, :blockers_resolved, :boolean, default: false, null: false
  end
end
