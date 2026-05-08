class MakeWhiteboardStrokesUserOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :whiteboard_strokes, :user_id, true
  end
end
