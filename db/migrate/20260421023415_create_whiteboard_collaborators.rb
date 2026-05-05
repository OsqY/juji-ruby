class CreateWhiteboardCollaborators < ActiveRecord::Migration[8.1]
  def change
    create_table :whiteboard_collaborators do |t|
      t.references :whiteboard, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :whiteboard_collaborators, [:whiteboard_id, :user_id], unique: true
  end
end
