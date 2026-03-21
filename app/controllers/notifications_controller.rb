class NotificationsController < ApplicationController
  before_action :set_user_notifications, only: [:index]

  def index
    @notifications = current_user.notifications.recent.limit(20)
  end

  def mark_as_read
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!
    redirect_to notifications_path, notice: "Notificación marcada como leída"
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_to notifications_path, notice: "Todas las notificaciones marcadas como leídas"
  end

  private

  def set_user_notifications
    @unread_count = current_user.notifications.unread.count
  end
end
