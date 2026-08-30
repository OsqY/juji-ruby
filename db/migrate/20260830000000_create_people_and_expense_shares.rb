class CreatePeopleAndExpenseShares < ActiveRecord::Migration[8.1]
  def change
    create_table :people do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :normalized_name, null: false

      t.timestamps
    end
    add_index :people, [ :user_id, :normalized_name ], unique: true

    create_table :expense_shares do |t|
      t.references :transaction, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.datetime :settled_at

      t.timestamps
    end
    add_index :expense_shares, [ :transaction_id, :person_id ], unique: true
  end
end
