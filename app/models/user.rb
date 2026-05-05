class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :daily_reports, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :habits, dependent: :destroy
  has_many :shopping_items, dependent: :destroy
  has_many :anonymous_forms, dependent: :destroy
  has_many :anonymous_form_responses, dependent: :nullify
  has_many :notifications, dependent: :destroy
  has_many :whiteboards, dependent: :destroy
  has_many :whiteboard_collaborators, dependent: :destroy
  has_many :shared_whiteboards, through: :whiteboard_collaborators, source: :whiteboard

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { new_record? || password.present? }
end
