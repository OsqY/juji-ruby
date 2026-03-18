# config/initializers/cors.rb
# Configuración CORS para Hotwire Native clients

cors_origins = case Rails.env
               when 'production'
                 # En producción, especificar dominios exactos
                 ENV.fetch('CORS_ORIGINS', 'localhost').split(',')
               when 'staging'
                 ['localhost', '127.0.0.1', ENV.fetch('STAGING_DOMAIN', 'localhost')]
               else
                 # Development: orígenes explícitos para evitar wildcard + credentials
                 [
                   'http://localhost:3000',
                   'http://127.0.0.1:3000',
                   'http://localhost:3001',
                   'http://127.0.0.1:3001'
                 ]
               end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins cors_origins
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options],
      credentials: true,
      max_age: 3600,
      expose: ['X-Hotwire-Native', 'X-Request-Id']
  end
end

Rails.logger.info "[CORS] Middleware configurado para Hotwire Native"
Rails.logger.info "[CORS] Orígenes permitidos: #{cors_origins.inspect}"

