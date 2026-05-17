# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotificationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/notification_mailer/alert_summary
  def alert_summary
    NotificationMailer.alert_summary
  end

  # Preview this email at http://localhost:3000/rails/mailers/notification_mailer/weekly_digest
  def weekly_digest
    NotificationMailer.weekly_digest
  end

  # Preview this email at http://localhost:3000/rails/mailers/notification_mailer/monthly_insights
  def monthly_insights
    NotificationMailer.monthly_insights
  end
end
