class ApplicationController < ActionController::Base
  include Authentication
  include HotwireNativeSupport
  include NativeResponseOptimization
  include NativeErrorHandling
  include DeepLinkSupport

  helper_method :current_user
  
  layout :set_layout

  private
    def current_user
      Current.user
    end

    def set_layout
      hotwire_native_client? ? "application_mobile" : "application"
    end
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
