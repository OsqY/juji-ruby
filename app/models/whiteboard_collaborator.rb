class WhiteboardCollaborator < ApplicationRecord
  belongs_to :whiteboard
  belongs_to :user

  validates :user_id, uniqueness: { scope: :whiteboard_id }
end
