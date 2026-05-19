module Sessions
  class ValidateController < ApplicationController
    skip_before_action :require_authentication

    def show
      if authenticated?
        render json: {
          authenticated: true,
          user: {
            id: current_user.id,
            email: current_user.email_address,
            display_name: current_user.display_name_or_email
          }
        }
      else
        render json: { authenticated: false }, status: :unauthorized
      end
    end
  end
end
