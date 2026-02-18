class Transaction < ApplicationRecord
  belongs_to :user
  enum :transaction_type, { expense: 0, income: 1 }

  validates :amount, presence: true, numericality: true
  validates :description, presence: true
  validates :transaction_type, presence: true
  validates :date, presence: true
end
