class AddNotNullToUserIdInTransactionsAndDailyReports < ActiveRecord::Migration[8.1]
  def up
    # Primero eliminar registros huérfanos si existen
    execute "DELETE FROM transactions WHERE user_id IS NULL"
    execute "DELETE FROM daily_reports WHERE user_id IS NULL"
    
    change_column_null :transactions, :user_id, false
    change_column_null :daily_reports, :user_id, false
  end

  def down
    change_column_null :transactions, :user_id, true
    change_column_null :daily_reports, :user_id, true
  end
end
