module AnonymousFormsHelper
  def human_question_type(question)
    case question.question_type
    when "single_choice"
      "Selección única"
    when "multiple_choice"
      "Selección múltiple"
    else
      "Respuesta libre"
    end
  end

  def response_answer_for(response, question)
    value = response.answers[question.id.to_s]

    return "Sin respuesta" if value.blank?
    return value.join(", ") if value.is_a?(Array)

    value
  end
end
