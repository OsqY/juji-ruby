# app/controllers/concerns/native_response_optimization.rb
# Optimiza las respuestas del servidor para clientes Hotwire Native
# Modifica headers, formatos de respuesta, y comportamiento según el cliente

module NativeResponseOptimization
  extend ActiveSupport::Concern

  included do
    before_action :optimize_response_for_native
    after_action :ensure_native_headers
  end

  private

  def optimize_response_for_native
    return unless hotwire_native_client?

    # Configurar respuestas más eficientes para Hotwire Native
    # La selección de layout móvil ya se maneja en ApplicationController#set_layout
  end

  def ensure_native_headers
    return unless hotwire_native_client?

    # Headers para optimizar rendering en Hotwire Native
    response.headers['X-Hotwire-Native'] = 'true'
    response.headers['Cache-Control'] = 'public, max-age=0, must-revalidate'

    # Headers de seguridad
    response.headers['X-Frame-Options'] = 'SAMEORIGIN'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-XSS-Protection'] = '1; mode=block'
  end

  # JSON responses optimizadas para native
  def json_response(data, status = :ok)
    render json: {
      success: status == :ok,
      data: data,
      native: true,
      timestamp: Time.current.iso8601
    }, status: status
  end

  # Evitar redirecciones innecesarias en Hotwire Native
  def redirect_to(options = {}, response_status = {})
    if hotwire_native_client? && turbo_frame_request?
      # Mantener el contexto actual en frames
      return super
    elsif hotwire_native_client?
      # Para navegación, usar Turbo native capabilities
      response_status[:turbo] = true
    end

    super(options, response_status)
  end

  # Validación mejorada para native clients
  def render_validation_errors(entity)
    if hotwire_native_client?
      head :unprocessable_entity,
           'X-Validation-Errors' => entity.errors.full_messages.join(', ')
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
