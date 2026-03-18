# app/controllers/concerns/deep_link_support.rb
# Soporte para deep linking en Hotwire Native

module DeepLinkSupport
  extend ActiveSupport::Concern

  included do
    before_action :handle_deep_link_if_present
  end

  private

  def handle_deep_link_if_present
    return unless hotwire_native_client?
    
    deep_link_url = request.headers['X-Deep-Link'] || params[:deep_link]
    return unless deep_link_url.present?

    begin
      link_info = DeepLinking.resolve_deep_link(deep_link_url)
      return unless link_info && DeepLinking.is_valid_deep_link?(link_info[:path])

      # Requerir autenticación si es necesario
      if link_info[:secure] && !authenticated?
        redirect_to new_session_path, notice: "Inicia sesión para acceder a este contenido"
        return
      end

      # Enrutar al deep link
      Rails.logger.info "[Deep Link] Resolviendo: #{link_info[:path]}"
      
      # Usar Turbo para navegar
      respond_to do |format|
        format.html do
          redirect_to link_info[:path], params: link_info[:params]
        end

        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('body', 
            partial: 'layouts/deep_link_redirect',
            locals: { target_url: link_info[:path], params: link_info[:params] }
          )
        end
      end
    rescue StandardError => e
      Rails.logger.warn "[Deep Link Error] #{e.message}"
      # Ignorar errores de deep link silenciosamente
    end
  end

  def deep_link_url_for(route_name, **options)
    if hotwire_native_client?
      # Retornar URL para deep linking en native
      url_for(route_name, **options)
    else
      # Comportamiento normal en web
      url_for(route_name, **options)
    end
  end
end
