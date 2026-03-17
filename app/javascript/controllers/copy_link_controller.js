import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "status"]

  async copy(event) {
    event.preventDefault()

    const value = this.sourceTarget?.value.toString() || ""
    if (!value) {
      this.setStatus("No hay enlace para copiar", true)
      return
    }

    let copied = false

    if (navigator.clipboard && window.isSecureContext) {
      try {
        await navigator.clipboard.writeText(value)
        copied = true
      } catch (_error) {
        copied = false
      }
    }

    if (!copied) {
      copied = this.copyWithSelectionFallback(value)
    }

    if (copied) {
      this.setStatus("Enlace copiado al portapapeles", false)
    } else {
      this.setStatus("No se pudo copiar, intenta manualmente", true)
    }
  }

  copyWithSelectionFallback(value) {
    this.sourceTarget.focus()
    this.sourceTarget.select()
    this.sourceTarget.setSelectionRange(0, value.length)

    try {
      return document.execCommand("copy")
    } catch (_error) {
      return false
    }
  }

  setStatus(message, isError) {
    if (!this.hasStatusTarget) {
      return
    }

    this.statusTarget.textContent = message
    this.statusTarget.style.color = isError ? "#D63031" : "var(--ink)"
  }
}
