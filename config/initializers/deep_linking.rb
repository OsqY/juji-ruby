# config/initializers/deep_linking.rb
# Configuración de Deep Linking para Hotwire Native
# Permite que URLs abiertas desde la app nativa se resuelvan correctamente

module DeepLinking
  # Patrones de deep links que soporta la app
  DEEP_LINK_PATTERNS = {
    dashboard: { path: '/', secure: false },
    daily_reports: { path: '/daily_reports', secure: true },
    daily_report: { path: '/daily_reports/:id', secure: true },
    transactions: { path: '/transactions', secure: true },
    transaction_new: { path: '/transactions/new', secure: true },
    budgets: { path: '/budgets', secure: true },
    budget: { path: '/budgets/:id', secure: true },
    projects: { path: '/projects', secure: true },
    project: { path: '/projects/:id', secure: true },
    habits: { path: '/habits', secure: true },
    shopping_items: { path: '/shopping_items', secure: true },
    anonymous_forms: { path: '/anonymous_forms', secure: true },
    guide: { path: '/guide', secure: false },
    session_new: { path: '/sessions/new', secure: false },
    registration_new: { path: '/registrations/new', secure: false }
  }.freeze

  def self.resolve_deep_link(url)
    # Validar y parsear el deep link
    uri = URI.parse(url)
  rescue URI::InvalidURIError, ArgumentError
    return nil
  else
    
    {
      path: uri.path,
      params: parse_params(uri.query),
      secure: should_require_auth?(uri.path)
    }
  end

  def self.parse_params(query_string)
    return {} if query_string.blank?
    
    Rack::Utils.parse_query(query_string)
  end

  def self.should_require_auth?(path)
    # Rutas públicas que no requieren autenticación
    public_paths = ['/guide', '/sessions/new', '/registrations/new', '/']
    !public_paths.include?(path) && !path.start_with?('/f/')
  end

  def self.is_valid_deep_link?(path)
    DEEP_LINK_PATTERNS.values.any? do |pattern|
      # Simple pattern matching - in production, use more robust matching
      path.start_with?(pattern[:path].split(':').first)
    end
  end
end

Rails.logger.info "[Deep Linking] Inicializador cargado con #{DeepLinking::DEEP_LINK_PATTERNS.size} patrones"
