import { Controller } from "@hotwired/stimulus"
import { initBridge, saveSession, clearSession, injectSessionCookie, isNative } from "capacitor/bridge"
import { initPushNotifications } from "capacitor/push"

export default class extends Controller {
  static values = {
    sessionId: String
  }

  async connect() {
    if (!isNative()) return

    // Initialize native plugins (splash, status bar, back button)
    await initBridge()

    // Initialize push notifications (FCM token registration)
    initPushNotifications().catch((err) => {
      console.warn("Push notifications init failed:", err)
    })

    // Restore session if we have a stored one
    await injectSessionCookie()

    // If Rails rendered with a session, store it locally
    if (this.hasSessionIdValue) {
      await saveSession(this.sessionIdValue)
    }

    // Listen for logout to clear native storage
    document.addEventListener("turbo:visit", this.handleNavigation)
  }

  disconnect() {
    document.removeEventListener("turbo:visit", this.handleNavigation)
  }

  handleNavigation = (event) => {
    // Detect logout by URL change
    if (event.detail?.url?.includes("/session") && event.detail?.url?.includes("_method=delete")) {
      clearSession()
    }
  }

  async logout() {
    if (isNative()) {
      await clearSession()
    }
  }
}
