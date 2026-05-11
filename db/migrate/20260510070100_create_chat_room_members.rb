class CreateChatRoomMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_room_members do |t|
      t.integer :chat_room_id, null: false
      t.integer :user_id, null: false
      t.integer :role, default: 2, null: false
      t.datetime :joined_at, null: false
      t.timestamps
    end

    add_index :chat_room_members, [:chat_room_id, :user_id], unique: true
    add_index :chat_room_members, :chat_room_id
    add_index :chat_room_members, :user_id
  end
end
