class AddFriendshipPairToFriendships < ActiveRecord::Migration[8.1]
  def change
    add_column :friendships, :friendship_pair, :string
    add_index :friendships, :friendship_pair, unique: true

    # Backfill existing records
    Friendship.reset_column_information
    Friendship.find_each do |f|
      f.update_column(:friendship_pair, "#{[f.requester_id, f.addressee_id].min}:#{[f.requester_id, f.addressee_id].max}")
    end

    change_column_null :friendships, :friendship_pair, false
  end
end
