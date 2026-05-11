class FriendsController < ApplicationController
  before_action :require_authentication

  def index
    @friends = current_user.friends
    @sent_requests = current_user.friendships_requested.pending
    @received_requests = current_user.friendships_received.pending
  end

  def pending
    @sent_requests = current_user.friendships_requested.pending.includes(:addressee)
    @received_requests = current_user.friendships_received.pending.includes(:requester)
  end

  def create
    addressee = User.find_by(email_address: params[:email]&.strip&.downcase)

    if addressee.nil?
      redirect_to friends_path, alert: "Usuario no encontrado."
      return
    end

    if addressee == current_user
      redirect_to friends_path, alert: "No puedes enviarte una solicitud a ti mismo."
      return
    end

    if current_user.friend_with?(addressee)
      redirect_to friends_path, alert: "Ya son amigos."
      return
    end

    existing = current_user.friendship_with(addressee)
    if existing&.pending?
      redirect_to friends_path, alert: "Ya existe una solicitud pendiente."
      return
    end

    @friendship = current_user.friendships_requested.create!(addressee: addressee)
    redirect_to friends_path, notice: "Solicitud enviada. Link de invitación: #{@friendship.invitation_url}"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to friends_path, alert: "No se pudo enviar la solicitud: #{e.message}"
  end

  def accept
    @friendship = current_user.friendships_received.pending.find(params[:id])
    @friendship.accept!
    redirect_to friends_path, notice: "Solicitud aceptada."
  rescue ActiveRecord::RecordNotFound
    redirect_to friends_path, alert: "Solicitud no encontrada."
  end

  def reject
    @friendship = current_user.friendships_received.pending.find(params[:id])
    @friendship.reject!
    redirect_to friends_path, notice: "Solicitud rechazada."
  rescue ActiveRecord::RecordNotFound
    redirect_to friends_path, alert: "Solicitud no encontrada."
  end

  def accept_invitation
    @friendship = Friendship.pending.find_by!(invitation_token: params[:token])

    unless authenticated?
      session[:after_login_redirect] = friend_invitation_path(token: params[:token])
      redirect_to new_session_path, alert: "Inicia sesión para aceptar la invitación."
      return
    end

    if @friendship.addressee != current_user
      redirect_to friends_path, alert: "Esta invitación no es para ti."
      return
    end

    @friendship.accept!
    redirect_to friends_path, notice: "¡Ahora son amigos!"
  rescue ActiveRecord::RecordNotFound
    redirect_to friends_path, alert: "Invitación no válida."
  end

  def destroy
    @friendship = Friendship.find(params[:id])

    unless @friendship.requester == current_user || @friendship.addressee == current_user
      redirect_to friends_path, alert: "No tienes permiso."
      return
    end

    @friendship.destroy
    redirect_to friends_path, notice: "Amistad eliminada."
  end
end
