module ChatRooms
  class MessagesController < ApplicationController
    before_action :require_authentication
    before_action :set_chat_room

    def create
      unless @chat_room.can_speak?(current_user)
        redirect_to @chat_room, alert: "No puedes escribir en esta sala."
        return
      end

      @message = @chat_room.messages.new(message_params.merge(user: current_user))

      if @message.save
        respond_to do |format|
          format.html { redirect_to @chat_room }
          format.turbo_stream
        end
      else
        redirect_to @chat_room, alert: "No se pudo enviar el mensaje."
      end
    end

    private
      def set_chat_room
        @chat_room = ChatRoom.active.find(params[:chat_room_id])
      end

      def message_params
        params.require(:message).permit(:content)
      end
  end
end
