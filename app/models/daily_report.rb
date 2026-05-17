class DailyReport < ApplicationRecord
  belongs_to :user
  has_one_attached :photo

  before_validation :sync_blocker_resolution

  validates :report_date, presence: true, uniqueness: { scope: :user_id, message: "ya tiene un reporte para esta fecha" }
  validates :work_title, presence: true
  validates :worked_by, presence: true
  validates :yesterday, presence: true
  validates :today, presence: true
  validate :photo_content_type_and_size

  MAX_PHOTO_SIZE = 5.megabytes
  ALLOWED_PHOTO_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze

  private
    def sync_blocker_resolution
      if blockers.blank?
        self.blockers_resolved = false
      elsif will_save_change_to_blockers? && !will_save_change_to_blockers_resolved?
        self.blockers_resolved = false
      end
    end

    def photo_content_type_and_size
      return unless photo.attached?

      unless photo.blob.content_type.in?(ALLOWED_PHOTO_TYPES)
        errors.add(:photo, "debe ser una imagen (JPEG, PNG, GIF, WebP)")
      end

      if photo.blob.byte_size > MAX_PHOTO_SIZE
        errors.add(:photo, "no debe superar los 5 MB")
      end
    end
end
