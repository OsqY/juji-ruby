class PushNotificationsController < ApplicationController
  before_action :require_authentication

  def register
    token = params[:fcm_token]&.strip
    if token.blank?
      render json: { error: "Token requerido" }, status: :unprocessable_entity
      return
    end

    current_user.update_column(:fcm_token, token)
    render json: { success: true }
  end

  def unregister
    current_user.update_column(:fcm_token, nil)
    render json: { success: true }
  end
end
