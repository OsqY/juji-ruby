class PushNotificationService
  def self.send_to_user(user, title:, body:, data: {})
    return unless user.fcm_token.present?

    send_fcm(user.fcm_token, title: title, body: body, data: data)
  end

  def self.send_to_users(users, title:, body:, data: {})
    tokens = users.where.not(fcm_token: nil).pluck(:fcm_token)
    return if tokens.empty?

    tokens.each do |token|
      send_fcm(token, title: title, body: body, data: data)
    end
  end

  private

  def self.send_fcm(token, title:, body:, data:)
    # Placeholder para integración con Firebase Cloud Messaging
    # En producción, esto haría una petición HTTP a la API de FCM
    # usando la server key de Firebase.
    Rails.logger.info "[FCM] Enviando push a #{token}: #{title} - #{body}"
  end
end
