class AddForeignKeysToChatAndFriends < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :chat_rooms, :users, column: :owner_id
    add_foreign_key :chat_room_members, :chat_rooms
    add_foreign_key :chat_room_members, :users
    add_foreign_key :messages, :chat_rooms
    add_foreign_key :messages, :users
    add_foreign_key :friendships, :users, column: :requester_id
    add_foreign_key :friendships, :users, column: :addressee_id

    add_index :friendships, [:addressee_id, :status]
    add_index :chat_rooms, [:owner_id, :archived_at]
  end
end
