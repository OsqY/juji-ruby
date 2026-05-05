class WhiteboardStroke < ApplicationRecord
  belongs_to :whiteboard
  belongs_to :user

  validates :stroke_data, presence: true
end
