import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

export default class extends Controller {
  static values = {
    spending: Object,
    habits: Object,
    alerts: Object
  }

  static targets = ["spendingCanvas", "habitsCanvas", "alertsCanvas"]

  connect() {
    this.charts = []
    this.renderSpendingChart()
    this.renderHabitsChart()
    this.renderAlertsChart()
  }

  disconnect() {
    this.charts.forEach((chart) => chart.destroy())
  }

  renderSpendingChart() {
    const labels = Object.keys(this.spendingValue || {})
    const data = Object.values(this.spendingValue || {})

    const chart = new Chart(this.spendingCanvasTarget, {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: "Gasto mensual",
          data,
          borderColor: "#2563eb",
          backgroundColor: "rgba(37, 99, 235, 0.15)",
          fill: true,
          tension: 0.3
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false
      }
    })

    this.charts.push(chart)
  }

  renderHabitsChart() {
    const labels = Object.keys(this.habitsValue || {})
    const data = Object.values(this.habitsValue || {})

    const chart = new Chart(this.habitsCanvasTarget, {
      type: "bar",
      data: {
        labels,
        datasets: [{
          label: "Cumplimiento de habitos (%)",
          data,
          backgroundColor: "rgba(16, 185, 129, 0.7)",
          borderColor: "#10b981",
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: { min: 0, max: 100 }
        }
      }
    })

    this.charts.push(chart)
  }

  renderAlertsChart() {
    const labels = Object.keys(this.alertsValue || {})
    const data = Object.values(this.alertsValue || {})

    const chart = new Chart(this.alertsCanvasTarget, {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: "Alertas",
          data,
          borderColor: "#f97316",
          backgroundColor: "rgba(249, 115, 22, 0.2)",
          fill: true,
          tension: 0.25
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false
      }
    })

    this.charts.push(chart)
  }
}
