# app/controllers/concerns/native_error_handling.rb
# Manejo de errores optimizado para Hotwire Native

module NativeErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :handle_standard_error
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  end

  private

  def handle_standard_error(exception)
    Rails.logger.error("Error in #{controller_name}##{action_name}: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))

    if hotwire_native_client?
      render_native_error(500, "Error del Servidor", "Algo salió mal. Por favor, intenta de nuevo.", "ERR")
    else
      render plain: "Internal Server Error", status: :internal_server_error
    end
  end

  def handle_not_found(exception)
    if hotwire_native_client?
      render_native_error(404, "No Encontrado", "La página que buscas no existe.", "404")
    else
      render plain: "Not Found", status: :not_found
    end
  end

  def handle_parameter_missing(exception)
    if hotwire_native_client?
      render_native_error(400, "Datos Incompletos", "Faltan datos requeridos para procesar tu solicitud.", "400")
    else
      render plain: "Bad Request", status: :bad_request
    end
  end

  def render_native_error(code, title, message, marker = "ERR")
    @code = code
    @title = title
    @message = message
    @marker = marker
    @details = Rails.env.development? ? "Code: #{code}" : nil

    render "errors/mobile_error", status: code, layout: false
  end

  def render_validation_errors(entity)
    if hotwire_native_client?
      errors = entity.errors.messages.map do |field, messages|
        "#{field}: #{messages.join(', ')}"
      end.join("; ")

      render_native_error(422, "Validación Fallida", errors, "422")
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
