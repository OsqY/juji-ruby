import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.frameState = new Map()
    this.onBeforeFetchRequest = this.captureState.bind(this)
    this.onFrameLoad = this.restoreState.bind(this)

    document.addEventListener("turbo:before-fetch-request", this.onBeforeFetchRequest)
    document.addEventListener("turbo:frame-load", this.onFrameLoad)
  }

  disconnect() {
    document.removeEventListener("turbo:before-fetch-request", this.onBeforeFetchRequest)
    document.removeEventListener("turbo:frame-load", this.onFrameLoad)
  }

  captureState(event) {
    const frame = this.findParentFrame(event.target)
    if (!frame || !frame.id) return

    const state = { scrollY: window.scrollY }
    const activeElement = document.activeElement

    if (activeElement && frame.contains(activeElement)) {
      const selector = this.focusSelectorFor(activeElement)
      if (selector) {
        state.selector = selector

        if (typeof activeElement.selectionStart === "number" && typeof activeElement.selectionEnd === "number") {
          state.selectionStart = activeElement.selectionStart
          state.selectionEnd = activeElement.selectionEnd
        }
      }
    }

    this.frameState.set(frame.id, state)
  }

  restoreState(event) {
    const frame = event.target
    if (!frame || !frame.id) return

    const state = this.frameState.get(frame.id)
    if (!state) return

    this.frameState.delete(frame.id)

    requestAnimationFrame(() => {
      if (typeof state.scrollY === "number") {
        window.scrollTo(0, state.scrollY)
      }

      if (!state.selector) return

      const focusElement = frame.querySelector(state.selector)
      if (!focusElement) return

      focusElement.focus({ preventScroll: true })

      if (typeof state.selectionStart === "number" && typeof focusElement.setSelectionRange === "function") {
        focusElement.setSelectionRange(state.selectionStart, state.selectionEnd ?? state.selectionStart)
      }
    })
  }

  findParentFrame(target) {
    return target instanceof Element ? target.closest("turbo-frame[id]") : null
  }

  focusSelectorFor(element) {
    if (element.id) {
      return `#${this.cssEscape(element.id)}`
    }

    const name = element.getAttribute("name")
    if (!name) return null

    return `[name="${this.cssEscape(name)}"]`
  }

  cssEscape(value) {
    if (window.CSS && typeof window.CSS.escape === "function") {
      return window.CSS.escape(value)
    }

    return String(value).replace(/([\\"\]])/g, "\\$1")
  }
}
