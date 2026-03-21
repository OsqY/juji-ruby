namespace :notifications do
  desc "Limpiar notificaciones leídas más de 30 días"
  task cleanup: :environment do
    count = Notification
      .where("read_at IS NOT NULL")
      .where("read_at < ?", 30.days.ago)
      .delete_all
    
    puts "✓ Se eliminaron #{count} notificaciones antiguas"
  end

  desc "Limpiar TODAS las notificaciones leídas"
  task cleanup_all_read: :environment do
    count = Notification.where("read_at IS NOT NULL").delete_all
    puts "✓ Se eliminaron #{count} notificaciones leídas"
  end

  desc "Estadísticas de notificaciones"
  task stats: :environment do
    puts "=== Estadísticas de Notificaciones ==="
    puts "Total: #{Notification.count}"
    puts "No leídas: #{Notification.unread.count}"
    puts "Leídas: #{Notification.read.count}"
    puts ""
    puts "Por tipo:"
    Notification.group(:notification_type).count.each do |type, count|
      puts "  #{type}: #{count}"
    end
    puts ""
    puts "Por usuario:"
    Notification.group(:user_id).count.each do |user_id, count|
      user = User.find(user_id)
      unread = user.notifications.unread.count
      puts "  #{user.email_address}: #{count} (#{unread} no leídas)"
    end
  end
end
