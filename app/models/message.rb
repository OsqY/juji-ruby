class Message < ApplicationRecord
  belongs_to :chat_room
  belongs_to :user, optional: true

  enum :message_type, { text: 0, system: 1, join: 2, leave: 3 }, prefix: true

  validates :content, presence: true, length: { maximum: 2000 }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_chat, -> { order(created_at: :asc) }

  after_create_commit :broadcast_message
  after_create_commit :notify_members, unless: :system_message?

  def author_name
    user&.display_name_or_email || "Anónimo"
  end

  def system_message?
    message_type_system? || message_type_join? || message_type_leave?
  end

  private
    def broadcast_message
      ChatRoomChannel.broadcast_to(
        chat_room,
        {
          id: id,
          content: content,
          author_name: author_name,
          user_id: user_id,
          message_type: message_type,
          created_at: created_at.strftime("%H:%M"),
          html: ApplicationController.render(
            partial: "messages/message",
            locals: { message: self }
          )
        }
      )
    end

    def notify_members
      return unless user_id.present?

      recipients = chat_room.members.where.not(id: user_id)
      recipients.each do |member|
        PushNotificationService.send_to_user(
          member,
          title: chat_room.name,
          body: "#{author_name}: #{content.truncate(100)}",
          data: { type: "chat_message", url: "/salas/#{chat_room.id}" }
        )
      end
    end
end
