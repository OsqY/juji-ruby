class DailyReport < ApplicationRecord
  belongs_to :user
  has_one_attached :photo

  before_validation :sync_blocker_resolution

  validates :report_date, presence: true, uniqueness: { scope: :user_id, message: "ya tiene un reporte para esta fecha" }
  validates :work_title, presence: true
  validates :worked_by, presence: true
  validates :yesterday, presence: true
  validates :today, presence: true

  private
    def sync_blocker_resolution
      if blockers.blank?
        self.blockers_resolved = false
      elsif will_save_change_to_blockers? && !will_save_change_to_blockers_resolved?
        self.blockers_resolved = false
      end
    end
end
