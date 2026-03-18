# config/initializers/webview_headers.rb
# Configuraciones de headers para WebView en Hotwire Native

namespace = -> (config) {
  config.action_dispatch.default_headers = {
    'X-UA-Compatible' => 'IE=edge,chrome=1',
    'X-Content-Type-Options' => 'nosniff',
    'X-Frame-Options' => 'SAMEORIGIN',
    'X-XSS-Protection' => '1; mode=block',
    # Permite WebView de Turbo Native
    'Permissions-Policy' => 'geolocation=*,microphone=*,camera=*'
  }
}

# Aplicar en development
namespace.call(Rails.application.config) if Rails.env.development? || Rails.env.test?

Rails.logger.info "[WebView Headers] Configuradas para Hotwire Native"
