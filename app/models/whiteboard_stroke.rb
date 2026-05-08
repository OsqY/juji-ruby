class WhiteboardStroke < ApplicationRecord
  belongs_to :whiteboard
  belongs_to :user, optional: true

  validates :stroke_data, presence: true
end
