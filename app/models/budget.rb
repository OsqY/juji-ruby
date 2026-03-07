class Budget < ApplicationRecord
  belongs_to :user

  before_validation :normalize_fields

  validates :category, presence: true
  validates :month, presence: true
  validates :monthly_limit, presence: true, numericality: { greater_than: 0 }
  validates :category, uniqueness: { scope: [ :user_id, :month ], message: "ya tiene un presupuesto para este mes" }

  scope :for_month, ->(date) { where(month: date.beginning_of_month) }

  private
    def normalize_fields
      self.category = category.to_s.strip.downcase
      self.month = month.to_date.beginning_of_month if month.present?
    end
end
