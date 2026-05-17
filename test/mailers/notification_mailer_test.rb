require "test_helper"

class NotificationMailerTest < ActionMailer::TestCase
  test "alert_summary" do
    mail = NotificationMailer.alert_summary
    assert_equal "Alert summary", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "weekly_digest" do
    mail = NotificationMailer.weekly_digest
    assert_equal "Weekly digest", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "monthly_insights" do
    mail = NotificationMailer.monthly_insights
    assert_equal "Monthly insights", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
