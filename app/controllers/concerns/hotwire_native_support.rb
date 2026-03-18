# app/controllers/concerns/hotwire_native_support.rb
# Provee métodos para ajustar respuestas según si es un cliente nativo
# Mantiene compatibilidad con web y optimiza para Hotwire Native

module HotwireNativeSupport
  extend ActiveSupport::Concern

  included do
    before_action :detect_hotwire_native
    helper_method :hotwire_native_client?, :hotwire_native_app?
  end

  private

  def detect_hotwire_native
    @hotwire_native = HotwireNative.native_client?(request.user_agent)
    Rails.logger.debug "[Hotwire Native] Detected native client: #{@hotwire_native}" if Rails.env.development?
  end

  def hotwire_native_client?
    @hotwire_native || false
  end

  def hotwire_native_app?
    hotwire_native_client?
  end

  # Helpers para respuestas específicas de Hotwire Native
  def native_response_headers
    response.set_header("X-Hotwire-Native", "true") if hotwire_native_client?
  end
end
