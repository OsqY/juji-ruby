module NotificationsHelper
  def notification_title(notification)
    case notification.notification_type
    when "budget_exceeded"
      "⚠️ Presupuesto Superado"
    when "no_report_3_days"
      "📋 Reportes Pendientes"
    when "project_no_progress"
      "📊 Proyecto sin Avances"
    else
      "Notificación"
    end
  end

  def notification_color(notification)
    case notification.notification_type
    when "budget_exceeded"
      "#FF6B6B"
    when "no_report_3_days"
      "#FFA500"
    when "project_no_progress"
      "#4ECDC4"
    else
      "#2D5A27"
    end
  end
end
