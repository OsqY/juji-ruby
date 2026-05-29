import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["group"]

  connect() {
    this.onBeforeVisit = this.closeAll.bind(this)
    this.onBeforeCache = this.closeAll.bind(this)

    document.addEventListener("turbo:before-visit", this.onBeforeVisit)
    document.addEventListener("turbo:before-cache", this.onBeforeCache)
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this.onBeforeVisit)
    document.removeEventListener("turbo:before-cache", this.onBeforeCache)
  }

  handleToggle(event) {
    const openedGroup = event.currentTarget
    if (!openedGroup.open) return

    this.closeAll(openedGroup)
  }

  closeOnLinkClick(event) {
    if (event.target.closest("select")) return

    const link = event.target.closest("a[href]")
    if (!link) return

    this.closeAll()
  }

  closeAll(except = null) {
    this.groupTargets.forEach((group) => {
      if (group !== except) group.open = false
    })
  }
}
