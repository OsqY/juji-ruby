class AnonymousForm < ApplicationRecord
  belongs_to :user

  has_many :questions, -> { order(:position, :id) }, class_name: "AnonymousFormQuestion", dependent: :destroy, inverse_of: :anonymous_form
  has_many :responses, class_name: "AnonymousFormResponse", dependent: :destroy, inverse_of: :anonymous_form

  accepts_nested_attributes_for :questions, allow_destroy: true

  before_validation :assign_token, on: :create

  validates :title, presence: true
  validates :token, presence: true, uniqueness: true
  validates :response_limit, numericality: { only_integer: true, greater_than: 0 }
  validate :must_have_questions

  def open_for_responses?
    responses_count < response_limit
  end

  def remaining_responses
    [ response_limit - responses_count, 0 ].max
  end

  private
    def assign_token
      self.token ||= SecureRandom.urlsafe_base64(12)
    end

    def must_have_questions
      return if questions.reject(&:marked_for_destruction?).any?

      errors.add(:base, "Debe agregar al menos una pregunta")
    end
end
