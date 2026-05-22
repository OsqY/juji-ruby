require "test_helper"

class NotificationMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:one)
  end

  test "alert_summary" do
    @user.notifications.create!(message: "Hello", notification_type: :budget_exceeded)
    mail = NotificationMailer.alert_summary(@user)
    assert_equal "Tienes 1 alerta(s) pendiente(s) en Juji", mail.subject
    assert_equal [ @user.email_address ], mail.to
    assert_match "Hello", mail.body.encoded
  end

  test "weekly_digest" do
    mail = NotificationMailer.weekly_digest(@user)
    assert_equal "Tu resumen semanal de Juji", mail.subject
    assert_equal [ @user.email_address ], mail.to
  end

  test "monthly_insights" do
    mail = NotificationMailer.monthly_insights(@user)
    assert_equal "Tus insights de #{I18n.l(Date.current, format: '%B %Y')}", mail.subject
    assert_equal [ @user.email_address ], mail.to
  end
end
