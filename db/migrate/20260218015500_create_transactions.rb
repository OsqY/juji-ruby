class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :description, null: false
      t.integer :transaction_type, null: false, default: 0
      t.string :category
      t.date :date, null: false

      t.timestamps
    end
    add_index :transactions, :date
  end
end
