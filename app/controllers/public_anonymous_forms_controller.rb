class PublicAnonymousFormsController < ApplicationController
  allow_unauthenticated_access

  before_action :set_anonymous_form

  def show
    @questions = @anonymous_form.questions
    @response = @anonymous_form.responses.new
  end

  def create_response
    answers, validation_errors = normalized_answers_from_params
    @response = @anonymous_form.responses.new(answers: answers)
    @response.user = current_user if authenticated?

    validation_errors.each { |message| @response.errors.add(:base, message) }

    if @response.errors.empty?
      @anonymous_form.with_lock do
        @anonymous_form.reload

        if @anonymous_form.open_for_responses?
          @response.save
        else
          @response.errors.add(:base, "Este formulario ya alcanzó su límite de respuestas")
        end
      end
    end

    if @response.errors.empty? && @response.new_record? && @anonymous_form.responses.exists?(user: current_user)
      @response.errors.add(:base, "Ya respondiste este formulario")
    end

    if @response.errors.empty?
      redirect_to public_anonymous_form_path(@anonymous_form.token, submitted: 1), notice: "Respuesta enviada. Gracias por participar."
    else
      @questions = @anonymous_form.questions
      flash.now[:alert] = @response.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  private
    def set_anonymous_form
      @anonymous_form = AnonymousForm.includes(:questions).find_by!(token: params[:token])
    end

    def normalized_answers_from_params
      raw_answers = params[:answers].is_a?(ActionController::Parameters) ? params[:answers].to_unsafe_h : {}
      answers = {}
      errors = []

      @anonymous_form.questions.each do |question|
        key = question.id.to_s

        case question.question_type
        when "free_text"
          value = raw_answers[key].to_s.strip
          validate_required_answer(question, value, errors)
          answers[key] = value if value.present?
        when "single_choice"
          value = raw_answers[key].to_s.strip
          validate_required_answer(question, value, errors)

          if value.present? && !question.options.include?(value)
            errors << "La pregunta '#{question.prompt}' recibió una opción inválida"
          end

          answers[key] = value if value.present?
        when "multiple_choice"
          values = Array(raw_answers[key]).map { |value| value.to_s.strip }.reject(&:blank?).uniq
          validate_required_answer(question, values, errors)

          invalid_options = values - question.options
          if invalid_options.any?
            errors << "La pregunta '#{question.prompt}' recibió opciones inválidas"
          end

          answers[key] = values if values.any?
        end
      end

      [ answers, errors ]
    end

    def validate_required_answer(question, value, errors)
      return unless question.required?
      return if value.present?

      errors << "La pregunta '#{question.prompt}' es obligatoria"
    end
end
