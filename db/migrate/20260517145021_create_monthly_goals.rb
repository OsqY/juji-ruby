class CreateMonthlyGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :monthly_goals do |t|
      t.references :user, null: false, foreign_key: true
      t.string :goal_type, null: false
      t.decimal :target_value, precision: 10, scale: 2, null: false
      t.decimal :current_value, precision: 10, scale: 2, default: 0
      t.date :month, null: false
      t.string :category
      t.integer :status, default: 0
      t.string :title, null: false
      t.text :description

      t.timestamps
    end

    add_index :monthly_goals, [:user_id, :month]
    add_index :monthly_goals, [:user_id, :goal_type]
  end
end
