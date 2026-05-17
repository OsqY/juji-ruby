import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

export default class extends Controller {
  static values = {
    spending: Object,
    habits: Object,
    alerts: Object,
    balance: Object
  }

  static targets = ["spendingCanvas", "habitsCanvas", "alertsCanvas", "balanceCanvas"]

  connect() {
    this.charts = []
    this.i18n = {
      monthlySpending: this.element.dataset.i18nMonthlySpending || "Gasto mensual (L.)",
      habitCompletion: this.element.dataset.i18nHabitCompletion || "Cumplimiento de hábitos (%)",
      alertsGenerated: this.element.dataset.i18nAlertsGenerated || "Alertas generadas",
      weeklyBalance: this.element.dataset.i18nWeeklyBalance || "Balance semanal (L.)"
    }
    this.renderSpendingChart()
    this.renderHabitsChart()
    this.renderAlertsChart()
    this.renderBalanceChart()
  }

  disconnect() {
    this.charts.forEach((chart) => chart.destroy())
  }

  renderSpendingChart() {
    const labels = Object.keys(this.spendingValue || {})
    const data = Object.values(this.spendingValue || {})
    const color = this.cssVar("--expense-text") || "#d63031"

    const chart = new Chart(this.spendingCanvasTarget, {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: this.i18n.monthlySpending,
          data,
          borderColor: color,
          backgroundColor: this.hexToRgba(color, 0.15),
          fill: true,
          tension: 0.3,
          borderWidth: 3,
          pointBackgroundColor: this.cssVar("--paper") || "#fff",
          pointBorderColor: color,
          pointBorderWidth: 2,
          pointRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false }
        },
        scales: {
          x: { grid: { display: false }, ticks: { font: { family: "Inter" } } },
          y: { grid: { color: this.cssVar("--muted-gray") || "#e5e5e5" }, ticks: { font: { family: "Inter" } } }
        }
      }
    })

    this.charts.push(chart)
  }

  renderHabitsChart() {
    const labels = Object.keys(this.habitsValue || {})
    const data = Object.values(this.habitsValue || {})
    const color = this.cssVar("--income-text") || "#00b894"

    const chart = new Chart(this.habitsCanvasTarget, {
      type: "bar",
      data: {
        labels,
        datasets: [{
          label: this.i18n.habitCompletion,
          data,
          backgroundColor: color,
          borderColor: color,
          borderWidth: 2,
          borderRadius: 0,
          borderSkipped: false
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false }
        },
        scales: {
          y: { min: 0, max: 100, ticks: { font: { family: "Inter" } } },
          x: { grid: { display: false }, ticks: { font: { family: "Inter" } } }
        }
      }
    })

    this.charts.push(chart)
  }

  renderAlertsChart() {
    const labels = Object.keys(this.alertsValue || {})
    const data = Object.values(this.alertsValue || {})
    const color = this.cssVar("--accent-blue") || "#b97a07"

    const chart = new Chart(this.alertsCanvasTarget, {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: this.i18n.alertsGenerated,
          data,
          borderColor: color,
          backgroundColor: this.hexToRgba(color, 0.2),
          fill: true,
          tension: 0.25,
          borderWidth: 3,
          pointBackgroundColor: this.cssVar("--paper") || "#fff",
          pointBorderColor: color,
          pointBorderWidth: 2,
          pointRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false }
        },
        scales: {
          x: { grid: { display: false }, ticks: { font: { family: "Inter" } } },
          y: { grid: { color: this.cssVar("--muted-gray") || "#e5e5e5" }, ticks: { font: { family: "Inter" } } }
        }
      }
    })

    this.charts.push(chart)
  }

  renderBalanceChart() {
    const labels = Object.keys(this.balanceValue || {})
    const data = Object.values(this.balanceValue || {})
    const positive = this.cssVar("--income-text") || "#00b894"
    const negative = this.cssVar("--expense-text") || "#d63031"

    const chart = new Chart(this.balanceCanvasTarget, {
      type: "bar",
      data: {
        labels,
        datasets: [{
          label: this.i18n.weeklyBalance,
          data,
          backgroundColor: data.map(v => v >= 0 ? positive : negative),
          borderColor: data.map(v => v >= 0 ? positive : negative),
          borderWidth: 2,
          borderRadius: 0,
          borderSkipped: false
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false }
        },
        scales: {
          x: { grid: { display: false }, ticks: { font: { family: "Inter" } } },
          y: { grid: { color: this.cssVar("--muted-gray") || "#e5e5e5" }, ticks: { font: { family: "Inter" } } }
        }
      }
    })

    this.charts.push(chart)
  }

  cssVar(name) {
    return getComputedStyle(document.documentElement).getPropertyValue(name).trim() || null
  }

  hexToRgba(hex, alpha) {
    const r = parseInt(hex.slice(1, 3), 16)
    const g = parseInt(hex.slice(3, 5), 16)
    const b = parseInt(hex.slice(5, 7), 16)
    return `rgba(${r}, ${g}, ${b}, ${alpha})`
  }
}
