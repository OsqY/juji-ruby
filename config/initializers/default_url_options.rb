Rails.application.routes.default_url_options[:host] = Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost"
