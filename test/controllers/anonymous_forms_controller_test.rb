require "test_helper"

class AnonymousFormsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)

    @anonymous_form = @user.anonymous_forms.create!(
      title: "Encuesta interna",
      response_limit: 3,
      questions_attributes: {
        "0" => {
          prompt: "¿Cómo calificas el servicio?",
          question_type: "single_choice",
          required: true,
          options_text: "Excelente\nBueno\nMalo",
          position: 0
        }
      }
    )
  end

  test "should get index" do
    get anonymous_forms_path
    assert_response :success
  end

  test "should get new" do
    get new_anonymous_form_path
    assert_response :success
  end

  test "should show form" do
    get anonymous_form_path(@anonymous_form)
    assert_response :success
  end

  test "should create anonymous form" do
    assert_difference("AnonymousForm.count", 1) do
      post anonymous_forms_path, params: {
        anonymous_form: {
          title: "Encuesta externa",
          description: "Formulario para clientes",
          response_limit: 5,
          questions_attributes: {
            "0" => {
              prompt: "¿Recomendarías nuestro producto?",
              question_type: "single_choice",
              required: "1",
              options_text: "Sí\nNo",
              position: 0
            },
            "1" => {
              prompt: "Comentarios adicionales",
              question_type: "free_text",
              required: "0",
              options_text: "",
              position: 1
            }
          }
        }
      }
    end

    assert_redirected_to anonymous_form_path(AnonymousForm.order(:id).last)
  end

  test "requires authentication" do
    sign_out

    get anonymous_forms_path
    assert_redirected_to new_session_path
  end
end
