import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hidden", "select", "custom", "customWrap"]

  connect() {
    this.sync()
  }

  selectChanged() {
    this.sync()
  }

  customChanged() {
    this.sync()
  }

  sync() {
    if (!this.hasHiddenTarget || !this.hasSelectTarget) return

    const newValue = this.selectTarget.dataset.newValue || "__new__"
    const isNew = this.selectTarget.value === newValue

    if (this.hasCustomWrapTarget) {
      this.customWrapTarget.style.display = isNew ? "block" : "none"
    }

    const selectedValue = isNew && this.hasCustomTarget
      ? this.customTarget.value
      : this.selectTarget.value

    this.hiddenTarget.value = selectedValue
  }
}
