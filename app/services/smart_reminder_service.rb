class SmartReminderService
  def self.check_and_send_reminders
    User.where(notify_by_email: true).find_each do |user|
      check_daily_reminders(user)
      check_weekly_reminders(user)
      check_monthly_reminders(user)
    end
  end

  def self.check_daily_reminders(user)
    return unless should_send_daily?(user)

    # Check for missing daily report
    latest_report = user.daily_reports.order(report_date: :desc).pick(:report_date)
    if latest_report.nil? || latest_report < Date.current - 1.day
      NotificationMailer.alert_summary(user).deliver_later
      user.update!(last_email_sent_at: Time.current)
      return
    end

    # Check habit reminders (if habits exist and none completed today)
    if user.habits.any?
      today_logs = HabitLog.joins(:habit).where(habits: { user_id: user.id }, log_date: Date.current, completed: true).count
      if today_logs == 0
        send_reminder_email(user, "habits", "No has completado ningún hábito hoy")
        user.update!(last_email_sent_at: Time.current)
        return
      end
    end
  end

  def self.check_weekly_reminders(user)
    return unless should_send_weekly?(user)
    return unless Date.current.monday?

    NotificationMailer.weekly_digest(user).deliver_later
    user.update!(last_email_sent_at: Time.current)
  end

  def self.check_monthly_reminders(user)
    return unless should_send_monthly?(user)
    return unless Date.current.day == 1

    NotificationMailer.monthly_insights(user).deliver_later
    user.update!(last_email_sent_at: Time.current)
  end

  private

  def self.should_send_daily?(user)
    return false if user.email_frequency != "daily"
    return true if user.last_email_sent_at.nil?
    user.last_email_sent_at < 20.hours.ago
  end

  def self.should_send_weekly?(user)
    return false unless %w[daily weekly].include?(user.email_frequency)
    return true if user.last_email_sent_at.nil?
    user.last_email_sent_at < 6.days.ago
  end

  def self.should_send_monthly?(user)
    return true if user.last_email_sent_at.nil?
    user.last_email_sent_at < 25.days.ago
  end

  def self.send_reminder_email(user, type, message)
    Notification.create!(user: user, notification_type: "reminder", message: message)
    # Could also send an email here if needed
  end
end
