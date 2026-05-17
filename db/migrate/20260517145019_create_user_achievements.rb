class CreateUserAchievements < ActiveRecord::Migration[8.1]
  def change
    create_table :user_achievements do |t|
      t.references :user, null: false, foreign_key: true
      t.string :achievement_type
      t.string :title
      t.text :description
      t.datetime :unlocked_at
      t.string :icon

      t.timestamps
    end

    add_index :user_achievements, [:user_id, :achievement_type], unique: true
  end
end
