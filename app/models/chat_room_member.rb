class ChatRoomMember < ApplicationRecord
  belongs_to :chat_room
  belongs_to :user

  enum :role, { owner: 0, admin: 1, member: 2 }

  validates :user_id, uniqueness: { scope: :chat_room_id }
  validates :joined_at, presence: true

  after_create :create_join_message, if: -> { member? }
  after_destroy :create_leave_message, if: -> { member? }

  private
    def create_join_message
      chat_room.messages.create!(
        user: nil,
        content: "#{user.display_name_or_email} se unió a la sala",
        message_type: :system
      )
    end

    def create_leave_message
      chat_room.messages.create!(
        user: nil,
        content: "#{user.display_name_or_email} salió de la sala",
        message_type: :system
      )
    end
end
