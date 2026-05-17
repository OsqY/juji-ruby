class Rack::Attack
  # Throttle login attempts by IP address
  throttle("logins/ip", limit: 5, period: 20.seconds) do |request|
    if request.path == "/session" && request.post?
      request.ip
    end
  end

  # Throttle login attempts by email address
  throttle("logins/email", limit: 5, period: 20.seconds) do |request|
    if request.path == "/session" && request.post?
      request.params["email_address"].to_s.downcase.strip
    end
  end

  # Throttle password reset attempts
  throttle("passwords/ip", limit: 3, period: 60.seconds) do |request|
    if request.path == "/passwords" && request.post?
      request.ip
    end
  end

  # Throttle registrations
  throttle("registrations/ip", limit: 3, period: 60.seconds) do |request|
    if request.path == "/registrations" && request.post?
      request.ip
    end
  end

  # Throttle exports (resource-intensive)
  throttle("exports/ip", limit: 10, period: 60.seconds) do |request|
    if request.path == "/exports" && request.post?
      request.ip
    end
  end

  # Throttle public form submissions
  throttle("form_responses/ip", limit: 5, period: 60.seconds) do |request|
    if request.path.match?(%r{^/f/[^/]+/responses$}) && request.post?
      request.ip
    end
  end
end
