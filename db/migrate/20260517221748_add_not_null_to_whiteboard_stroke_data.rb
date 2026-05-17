class AddNotNullToWhiteboardStrokeData < ActiveRecord::Migration[8.1]
  def change
    change_column_null :whiteboard_strokes, :stroke_data, false
  end
end
