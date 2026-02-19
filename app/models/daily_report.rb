class DailyReport < ApplicationRecord
  belongs_to :user
  has_one_attached :photo
  validates :report_date, presence: true, uniqueness: true
  validates :yesterday, presence: true
  validates :today, presence: true
end
