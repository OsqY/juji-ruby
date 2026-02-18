class CreateDailyReports < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_reports do |t|
      t.date :report_date
      t.text :yesterday
      t.text :today
      t.text :blockers
      t.text :additional_details

      t.timestamps
    end
    add_index :daily_reports, :report_date
  end
end
