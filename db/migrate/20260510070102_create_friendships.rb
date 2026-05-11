class CreateFriendships < ActiveRecord::Migration[8.1]
  def change
    create_table :friendships do |t|
      t.integer :requester_id, null: false
      t.integer :addressee_id, null: false
      t.integer :status, default: 0, null: false
      t.string :invitation_token, null: false
      t.datetime :accepted_at
      t.timestamps
    end

    add_index :friendships, [:requester_id, :addressee_id], unique: true
    add_index :friendships, :invitation_token, unique: true
    add_index :friendships, :requester_id
    add_index :friendships, :addressee_id
  end
end
