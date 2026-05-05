class CreateWhiteboardStrokes < ActiveRecord::Migration[8.1]
  def change
    create_table :whiteboard_strokes do |t|
      t.references :whiteboard, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.json :stroke_data

      t.timestamps
    end
  end
end
