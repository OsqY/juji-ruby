class CreateUserStreaks < ActiveRecord::Migration[8.1]
  def change
    create_table :user_streaks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :streak_type, null: false
      t.integer :current_streak, default: 0
      t.integer :longest_streak, default: 0
      t.date :last_activity_date

      t.timestamps
    end

    add_index :user_streaks, [:user_id, :streak_type], unique: true
  end
end
