class AddUserToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :transactions, :user, null: true, foreign_key: true
  end
end
