# app/middleware/hotwire_native_middleware.rb
# Middleware para optimizar respuestas hacia clientes Hotwire Native

class HotwireNativeMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    user_agent = env['HTTP_USER_AGENT'] || ''
    is_native = HotwireNative.native_client?(user_agent)

    # Ejecutar la aplicación
    status, headers, body = @app.call(env)

    # Agregar headers específicos para clientes nativos
    if is_native
      headers['X-Hotwire-Native'] = 'true'
      headers['X-Content-Type-Options'] = 'nosniff'
      # Ensure Turbo funciona correctamente
      headers['Cache-Control'] = 'public, max-age=0, must-revalidate'
    end

    [status, headers, body]
  end
end
