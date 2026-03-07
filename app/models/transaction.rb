class Transaction < ApplicationRecord
  belongs_to :user
  enum :transaction_type, { expense: 0, income: 1 }

  before_validation :normalize_category

  validates :amount, presence: true, numericality: true
  validates :description, presence: true
  validates :transaction_type, presence: true
  validates :date, presence: true
  validates :category, presence: true

  private
    def normalize_category
      self.category = category.to_s.strip.downcase if category.present?
    end
end
