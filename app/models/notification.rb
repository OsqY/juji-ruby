class Notification < ApplicationRecord
  belongs_to :user

  enum :notification_type, {
    budget_exceeded: "budget_exceeded",
    no_report_3_days: "no_report_3_days",
    project_no_progress: "project_no_progress"
  }

  validates :notification_type, presence: true
  validates :message, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def unread?
    read_at.blank?
  end

  def mark_as_read!
    update(read_at: Time.current) if unread?
  end
end
