class FixNotificationType < ActiveRecord::Migration[8.1]
  def change
    add_index :notifications, :notification_type
  end
end
