class CreateBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :budgets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :category, null: false
      t.date :month, null: false
      t.decimal :monthly_limit, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :budgets, [ :user_id, :month, :category ], unique: true
  end
end
