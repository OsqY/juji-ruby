# Hotwire Native Configuration
# Detecta y configura el comportamiento de la app para clients nativos

module HotwireNative
  # User agents que identifican clients de Hotwire Native
  NATIVE_USER_AGENTS = [
    'TurboNative',
    'Turbo-Native',
    'hotwire-native',
    /Turbo Native/i,
    /Hotwire Native/i,
    /TurboAndroid/i,
    /TurboIOS/i,
    /Turbo\/.*Electron/i  # Para Electron apps que usen Turbo
  ].freeze

  # Browsers tradicionales que NO deben tratarse como nativos
  EXCLUDED_BROWSERS = [
    /Chrome/i,
    /Firefox/i,
    /Safari/i,
    /Edge/i,
    /Chromium/i,
    /Mozilla/i
  ].freeze

  def self.native_client?(user_agent)
    return false if user_agent.blank?
    
    # Primero verificar patrones nativos
    is_native = NATIVE_USER_AGENTS.any? do |pattern|
      case pattern
      when Regexp
        pattern.match?(user_agent)
      else
        user_agent.include?(pattern)
      end
    end

    return is_native if is_native

    # Si no está explícitamente marcado como nativo, no es nativo
    false
  end

  # Detección avanzada usando user_agent_parser
  def self.client_info(user_agent)
    return { type: :unknown, browser: nil, os: nil } if user_agent.blank?

    if native_client?(user_agent)
      # Determinar si es iOS o Android
      platform = case user_agent
                 when /TurboIOS|iOS/i
                   :ios
                 when /TurboAndroid|Android/i
                   :android
                 else
                   :unknown
                 end

      { type: :native, platform: platform, user_agent: user_agent }
    else
      { type: :web, user_agent: user_agent }
    end
  end

  def self.should_render_native_layout?(user_agent)
    native_client?(user_agent)
  end
end

# Logging de configuración
Rails.logger.info "[Hotwire Native] Inicializador cargado"
if Rails.env.development?
  Rails.logger.debug "[Hotwire Native] Native user agents patterns: #{HotwireNative::NATIVE_USER_AGENTS.inspect}"
end

