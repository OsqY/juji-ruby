# app/helpers/hotwire_native_helper.rb
# Helpers para Hotwire Native en vistas

module HotwireNativeHelper
  def native_client_badge
    return unless hotwire_native_client? && Rails.env.development?
    
    content_tag :div, class: "hotwire-native-indicator", style: "position: fixed; bottom: 10px; right: 10px; background: #4CAF50; color: white; padding: 8px 12px; border-radius: 4px; z-index: 9999; font-size: 12px; font-weight: bold;" do
      "🚀 NATIVE CLIENT"
    end
  end

  def native_safe_content
    @hotwire_native ? "native" : "web"
  end

  # Evita contenido que no funciona bien en Hotwire Native
  def unless_native_only
    yield unless hotwire_native_client?
  end

  def only_if_native
    yield if hotwire_native_client?
  end
end
