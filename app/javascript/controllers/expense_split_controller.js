import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template", "row", "total", "amount", "assigned", "remaining"]

  connect() {
    if (this.rowTargets.length === 0) this.addRow()
    this.updateTotals()
  }

  addRow(event) {
    event?.preventDefault()
    const index = `${Date.now()}${this.rowTargets.length}`
    this.listTarget.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML.replaceAll("__INDEX__", index))
    this.updateTotals()
  }

  removeRow(event) {
    event.preventDefault()
    event.currentTarget.closest("[data-expense-split-target='row']")?.remove()
    if (this.rowTargets.length === 0) this.addRow()
    this.updateTotals()
  }

  splitEvenly(event) {
    event.preventDefault()
    const rows = this.rowTargets
    const totalCents = Math.round(this.number(this.totalTarget.value) * 100)
    if (rows.length === 0 || totalCents <= 0) return

    const centsPerPerson = Math.floor(totalCents / rows.length)
    const remainder = totalCents % rows.length
    rows.forEach((row, index) => {
      row.querySelector("[data-expense-split-target='amount']").value = ((centsPerPerson + (index < remainder ? 1 : 0)) / 100).toFixed(2)
    })
    this.updateTotals()
  }

  updateTotals() {
    const total = this.hasTotalTarget ? this.number(this.totalTarget.value) : 0
    const assigned = this.amountTargets.reduce((sum, input) => sum + this.number(input.value), 0)
    this.assignedTarget.textContent = this.money(assigned)
    this.remainingTarget.textContent = this.money(total - assigned)
    this.remainingTarget.classList.toggle("is-negative", assigned > total)
  }

  number(value) {
    const number = Number.parseFloat(value)
    return Number.isFinite(number) ? number : 0
  }

  money(value) {
    return `L. ${value.toFixed(2)}`
  }
}
