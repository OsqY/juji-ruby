require "test_helper"

class PublicAnonymousFormsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @anonymous_form = @user.anonymous_forms.create!(
      title: "Encuesta pública",
      response_limit: 2,
      questions_attributes: {
        "0" => {
          prompt: "Selecciona una opción",
          question_type: "single_choice",
          required: true,
          options_text: "A\nB\nC",
          position: 0
        },
        "1" => {
          prompt: "Puedes elegir varias",
          question_type: "multiple_choice",
          required: false,
          options_text: "X\nY\nZ",
          position: 1
        },
        "2" => {
          prompt: "Comentario",
          question_type: "free_text",
          required: false,
          options_text: "",
          position: 2
        }
      }
    )
  end

  test "should show public form without authentication" do
    get public_anonymous_form_path(@anonymous_form.token)
    assert_response :success
  end

  test "should create response" do
    question_one = @anonymous_form.questions.find_by!(question_type: :single_choice)
    question_two = @anonymous_form.questions.find_by!(question_type: :multiple_choice)
    question_three = @anonymous_form.questions.find_by!(question_type: :free_text)

    assert_difference("AnonymousFormResponse.count", 1) do
      post public_anonymous_form_responses_path(@anonymous_form.token), params: {
        answers: {
          question_one.id.to_s => "B",
          question_two.id.to_s => [ "X", "Z" ],
          question_three.id.to_s => "Todo bien"
        }
      }
    end

    assert_redirected_to public_anonymous_form_path(@anonymous_form.token, submitted: 1)
  end

  test "should reject invalid option" do
    question_one = @anonymous_form.questions.find_by!(question_type: :single_choice)

    assert_no_difference("AnonymousFormResponse.count") do
      post public_anonymous_form_responses_path(@anonymous_form.token), params: {
        answers: {
          question_one.id.to_s => "INVALIDA"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should reject when response limit reached" do
    question_one = @anonymous_form.questions.find_by!(question_type: :single_choice)

    @anonymous_form.responses.create!(answers: { question_one.id.to_s => "A" })
    @anonymous_form.responses.create!(answers: { question_one.id.to_s => "B" })

    assert_no_difference("AnonymousFormResponse.count") do
      post public_anonymous_form_responses_path(@anonymous_form.token), params: {
        answers: {
          question_one.id.to_s => "C"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should prevent authenticated user from answering twice" do
    sign_in_as(@user)
    question_one = @anonymous_form.questions.find_by!(question_type: :single_choice)

    assert_difference("AnonymousFormResponse.count", 1) do
      post public_anonymous_form_responses_path(@anonymous_form.token), params: {
        answers: {
          question_one.id.to_s => "A"
        }
      }
    end

    assert_no_difference("AnonymousFormResponse.count") do
      post public_anonymous_form_responses_path(@anonymous_form.token), params: {
        answers: {
          question_one.id.to_s => "B"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match(/Ya respondiste este formulario/i, @response.body)
  end
end
