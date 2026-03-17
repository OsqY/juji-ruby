class AnonymousFormQuestion < ApplicationRecord
  belongs_to :anonymous_form, inverse_of: :questions

  enum :question_type, {
    single_choice: 0,
    multiple_choice: 1,
    free_text: 2
  }

  validates :prompt, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :options_required_for_choice_questions

  def options
    options_text.to_s.lines.map { |line| line.strip }.reject(&:blank?).uniq
  end

  private
    def options_required_for_choice_questions
      return if free_text?
      return if options.size >= 2

      errors.add(:options_text, "debe tener al menos dos opciones")
    end
end
