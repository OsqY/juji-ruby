class AddCompositeIndexesForPerformance < ActiveRecord::Migration[8.1]
  def change
    add_index :notifications, [:user_id, :read_at]
    add_index :friendships, :status
    add_index :chat_rooms, :archived_at
    add_index :whiteboard_strokes, [:whiteboard_id, :created_at]
    add_index :transactions, [:user_id, :date]
    add_index :transactions, :category
  end
end
