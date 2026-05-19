import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner"]

  connect() {
    this.updateStatus()
    window.addEventListener("online", this.updateStatus)
    window.addEventListener("offline", this.updateStatus)
  }

  disconnect() {
    window.removeEventListener("online", this.updateStatus)
    window.removeEventListener("offline", this.updateStatus)
  }

  updateStatus = () => {
    if (navigator.onLine) {
      this.hideBanner()
    } else {
      this.showBanner()
    }
  }

  showBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.style.display = "block"
    }
  }

  hideBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.style.display = "none"
    }
  }
}
