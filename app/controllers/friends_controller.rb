class FriendsController < ApplicationController
  before_action :require_authentication

  def index
    @friends = current_user.friends
    @sent_requests = current_user.friendships_requested.pending
    @received_requests = current_user.friendships_received.pending
    current_user.ensure_invite_token!
  end

  def pending
    @sent_requests = current_user.friendships_requested.pending.includes(:addressee)
    @received_requests = current_user.friendships_received.pending.includes(:requester)
  end

  def accept_user_invite
    inviter = User.find_by!(invite_token: params[:token])

    unless authenticated?
      session[:after_login_redirect] = user_invite_path(token: params[:token])
      redirect_to new_session_path, alert: "Inicia sesión para enviar una solicitud de amistad."
      return
    end

    if inviter == current_user
      redirect_to friends_path, alert: "No puedes enviarte una solicitud a ti mismo."
      return
    end

    if current_user.friend_with?(inviter)
      redirect_to friends_path, notice: "Ya eres amigo de #{inviter.display_name_or_email}."
      return
    end

    existing = current_user.friendship_with(inviter)
    if existing&.pending?
      redirect_to friends_path, notice: "Ya existe una solicitud pendiente con #{inviter.display_name_or_email}."
      return
    end

    current_user.friendships_requested.create!(addressee: inviter)
    redirect_to friends_path, notice: "Solicitud enviada a #{inviter.display_name_or_email}."
  rescue ActiveRecord::RecordNotFound
    redirect_to friends_path, alert: "Link de invitación no válido."
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
