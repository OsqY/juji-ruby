import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input", "displayDay", "displayMonth", "displayYear", "picker"]

    connect() {
        this.refresh()
    }

    nextDay(e) {
        if (e) e.preventDefault()
        this.shiftDate(1)
    }

    prevDay(e) {
        if (e) e.preventDefault()
        this.shiftDate(-1)
    }

    shiftDate(days) {
        const current = this.getLocalDate()
        current.setDate(current.getDate() + days)
        this.setDate(current)
    }

    togglePicker(e) {
        if (e) e.preventDefault()
        this.pickerTarget.classList.toggle("hidden")
    }

    selectMonth(e) {
        const month = Number.parseInt(e.target.value)
        const current = this.getLocalDate()
        current.setMonth(month)
        this.setDate(current)
    }

    selectYear(e) {
        const year = Number.parseInt(e.target.value)
        const current = this.getLocalDate()
        current.setFullYear(year)
        this.setDate(current)
    }

    setDate(date) {
        const y = date.getFullYear()
        const m = String(date.getMonth() + 1).padStart(2, "0")
        const d = String(date.getDate()).padStart(2, "0")
        this.inputTarget.value = `${y}-${m}-${d}`
        this.refresh()
    }

    getLocalDate() {
        const val = this.inputTarget.value
        if (!val) return new Date()
        const [year, month, day] = val.split("-").map(Number)
        return new Date(year, month - 1, day)
    }

    refresh() {
        const date = this.getLocalDate()

        if (this.hasDisplayDayTarget) {
            this.displayDayTarget.textContent = date.toLocaleString("es-ES", { day: "2-digit" })
        }

        if (this.hasDisplayMonthTarget) {
            this.displayMonthTarget.textContent = date.toLocaleString("es-ES", { month: "long" }).toUpperCase()
        }

        if (this.hasDisplayYearTarget) {
            this.displayYearTarget.textContent = date.getFullYear()
        }
    }
}
