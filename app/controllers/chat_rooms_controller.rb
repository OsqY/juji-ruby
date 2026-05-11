class ChatRoomsController < ApplicationController
  before_action :set_chat_room, only: %i[ show destroy join leave invite kick ]
  before_action :require_authentication, except: %i[ public_show public_join ]
  before_action :authorize_chat_room, only: %i[ show destroy ]

  def index
    @my_rooms = current_user.joined_chat_rooms
                              .active
                              .excluding_direct_messages
                              .order(created_at: :desc)
    @public_rooms = ChatRoom.searchable
                            .excluding_direct_messages
                            .where.not(id: @my_rooms.select(:id))
                            .order(created_at: :desc)
                            .limit(50)
  end

  def new
    @chat_room = current_user.chat_rooms.new
  end

  def create
    @chat_room = current_user.chat_rooms.new(chat_room_params)

    if @chat_room.direct_message?
      # DMs are created from the friends page - we need the other user's email
      friend = User.find_by(email_address: params[:friend_email]&.strip&.downcase)
      if friend.nil?
        redirect_to friends_path, alert: "Amigo no encontrado."
        return
      end
      unless current_user.friend_with?(friend)
        redirect_to friends_path, alert: "No eres amigo de este usuario."
        return
      end
      existing_dm = current_user.dm_with(friend)
      if existing_dm
        redirect_to existing_dm, notice: "Ya tienes un chat con este amigo."
        return
      end
    end

    if @chat_room.save
      @chat_room.add_member(current_user, role: :owner)
      if @chat_room.direct_message? && friend
        @chat_room.add_member(friend, role: :member)
      end
      redirect_to @chat_room, notice: "Sala creada correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @messages = @chat_room.messages.for_chat.limit(100)
    @members = @chat_room.chat_room_members.includes(:user).order(role: :asc, joined_at: :asc)
  end

  def public_show
    @chat_room = ChatRoom.active.find_by!(token: params[:token])
    @is_member = authenticated? && @chat_room.member?(current_user)
    @can_join = authenticated? && @chat_room.can_join?(current_user)
    @messages = @chat_room.messages.for_chat.limit(20) if @is_member
  end

  def public_join
    @chat_room = ChatRoom.active.find_by!(token: params[:token])

    unless authenticated?
      redirect_to new_session_path, alert: "Debes iniciar sesión para unirte."
      return
    end

    if @chat_room.private_code? && params[:entry_code].blank?
      redirect_to public_chat_room_path(token: @chat_room.token), alert: "Se requiere un código de acceso."
      return
    end

    if @chat_room.private_code? && params[:entry_code] != @chat_room.entry_code
      redirect_to public_chat_room_path(token: @chat_room.token), alert: "Código de acceso incorrecto."
      return
    end

    if @chat_room.can_join?(current_user)
      @chat_room.add_member(current_user)
      redirect_to @chat_room, notice: "Te uniste a la sala."
    else
      redirect_to chat_rooms_path, alert: "No puedes unirte a esta sala."
    end
  end

  def join
    if @chat_room.can_join?(current_user)
      @chat_room.add_member(current_user)
      redirect_to @chat_room, notice: "Te uniste a la sala."
    else
      redirect_to chat_rooms_path, alert: "No puedes unirte a esta sala."
    end
  end

  def leave
    @chat_room.remove_member(current_user)
    redirect_to chat_rooms_path, notice: "Saliste de la sala."
  end

  def invite
    if @chat_room.owner?(current_user) || @chat_room.admin_or_owner?(current_user)
      redirect_to public_chat_room_path(token: @chat_room.token), notice: "Link de invitación: #{@chat_room.invitation_url}"
    else
      redirect_to @chat_room, alert: "No tienes permiso para invitar."
    end
  end

  def kick
    member = @chat_room.chat_room_members.find_by(user_id: params[:user_id])

    unless member
      redirect_to @chat_room, alert: "Miembro no encontrado."
      return
    end

    if !@chat_room.admin_or_owner?(current_user)
      redirect_to @chat_room, alert: "No tienes permiso para expulsar."
      return
    end

    if member.owner?
      redirect_to @chat_room, alert: "No puedes expulsar al dueño."
      return
    end

    if @chat_room.owner?(current_user) || (member.member? && !member.admin?)
      member.destroy
      redirect_to @chat_room, notice: "Miembro expulsado."
    else
      redirect_to @chat_room, alert: "No puedes expulsar a este miembro."
    end
  end

  def destroy
    @chat_room.update!(archived_at: Time.current)
    redirect_to chat_rooms_path, notice: "Sala eliminada."
  end

  private
    def set_chat_room
      @chat_room = ChatRoom.active.find(params[:id])
    end

    def authorize_chat_room
      unless @chat_room.member?(current_user) || @chat_room.open? || @chat_room.channel?
        redirect_to chat_rooms_path, alert: "No tienes acceso a esta sala."
      end
    end

    def chat_room_params
      params.require(:chat_room).permit(:name, :description, :room_type, :entry_code, :capacity).tap do |p|
        p[:capacity] = nil if p[:capacity].blank?
        p[:entry_code] = nil if p[:entry_code].blank?
      end
    end
end
