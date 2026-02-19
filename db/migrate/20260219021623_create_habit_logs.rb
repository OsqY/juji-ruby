class CreateHabitLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :habit_logs do |t|
      t.references :habit, null: false, foreign_key: true
      t.date :log_date
      t.boolean :completed, default: false

      t.timestamps
    end
  end
end
