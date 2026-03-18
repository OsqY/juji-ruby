# app/middleware/hotwire_native_middleware.rb
# Middleware para optimizar respuestas hacia clientes Hotwire Native

class HotwireNativeMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    user_agent = env['HTTP_USER_AGENT'] || ''
    is_native = HotwireNative.native_client?(user_agent)

    # Algunas WebViews envían `Origin: null` en formularios POST.
    # Rails lo trata como origen inválido para CSRF y responde 422.
    # Para clientes nativos removemos ese valor para que valide por token.
    if is_native && env['HTTP_ORIGIN'] == 'null'
      env.delete('HTTP_ORIGIN')
    end

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
