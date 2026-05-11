class CreateChatRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_rooms do |t|
      t.string :name, null: false
      t.text :description
      t.integer :room_type, default: 0, null: false
      t.string :entry_code
      t.integer :capacity
      t.string :token, null: false
      t.integer :owner_id, null: false
      t.datetime :archived_at
      t.timestamps
    end

    add_index :chat_rooms, :token, unique: true
    add_index :chat_rooms, :room_type
    add_index :chat_rooms, :owner_id
  end
end
