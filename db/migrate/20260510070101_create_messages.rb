class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.integer :chat_room_id, null: false
      t.integer :user_id
      t.text :content, null: false
      t.integer :message_type, default: 0, null: false
      t.timestamps
    end

    add_index :messages, [:chat_room_id, :created_at]
    add_index :messages, :user_id
  end
end
