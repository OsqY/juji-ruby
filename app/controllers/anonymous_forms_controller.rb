class AnonymousFormsController < ApplicationController
  before_action :set_anonymous_form, only: %i[ show destroy ]

  def index
    @anonymous_forms = current_user.anonymous_forms.includes(:questions).order(created_at: :desc)
  end

  def new
    @anonymous_form = current_user.anonymous_forms.new(response_limit: 20)
    @anonymous_form.questions.build(question_type: :free_text, required: true, position: 0)
  end

  def create
    @anonymous_form = current_user.anonymous_forms.new(anonymous_form_params)
    normalize_question_positions

    if @anonymous_form.save
      redirect_to anonymous_form_path(@anonymous_form), notice: "Formulario anónimo creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @public_link = public_anonymous_form_url(@anonymous_form.token)
    @responses = @anonymous_form.responses.order(created_at: :desc)
  end

  def destroy
    @anonymous_form.destroy
    redirect_to anonymous_forms_path, notice: "Formulario eliminado.", status: :see_other
  end

  private
    def set_anonymous_form
      @anonymous_form = current_user.anonymous_forms.find(params[:id])
    end

    def anonymous_form_params
      permitted = params.require(:anonymous_form).permit(
        :title,
        :description,
        :response_limit,
        questions_attributes: [ :prompt, :question_type, :required, :options_text, :position ]
      )

      return permitted unless permitted[:questions_attributes].present?

      cleaned = permitted[:questions_attributes].to_h.values.filter_map do |question|
        next if question[:prompt].to_s.strip.blank?

        question[:prompt] = question[:prompt].to_s.strip
        question[:options_text] = question[:options_text].to_s.strip
        question
      end

      permitted[:questions_attributes] = cleaned.each_with_index.to_h { |question, index| [ index.to_s, question ] }
      permitted
    end

    def normalize_question_positions
      @anonymous_form.questions.each_with_index do |question, index|
        question.position = index
      end
    end
end
