class ChatRoomChannel < ApplicationCable::Channel
  def subscribed
    @chat_room = ChatRoom.active.find_by(id: params[:room_id])

    if @chat_room && can_access?
      stream_for @chat_room
      transmit_recent_messages
    else
      reject
    end
  end

  def unsubscribed
    # Cleanup if needed
  end

  def speak(data)
    return unless @chat_room
    return unless can_speak?

    message = @chat_room.messages.create!(
      user: current_user,
      content: data["message"],
      message_type: :text
    )
  end

  private
    def can_access?
      return false unless current_user
      @chat_room.member?(current_user) || public_or_channel?
    end

    def can_speak?
      return false unless current_user
      @chat_room.can_speak?(current_user)
    end

    def public_or_channel?
      @chat_room.open? || @chat_room.channel?
    end

    def transmit_recent_messages
      messages = @chat_room.messages.for_chat.limit(50).map do |msg|
        {
          id: msg.id,
          content: msg.content,
          author_name: msg.author_name,
          user_id: msg.user_id,
          message_type: msg.message_type,
          created_at: msg.created_at.strftime("%H:%M")
        }
      end

      transmit({ type: "init", messages: messages })
    end
end
