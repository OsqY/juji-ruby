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

    const chart = new Chart(this.spendingCanvasTarget, {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: "Gasto mensual (L.)",
          data,
          borderColor: "#d63031",
          backgroundColor: "rgba(214, 48, 49, 0.15)",
          fill: true,
          tension: 0.3,
          borderWidth: 3,
          pointBackgroundColor: "#fff",
          pointBorderColor: "#d63031",
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
          y: { grid: { color: "#e5e5e5" }, ticks: { font: { family: "Inter" } } }
        }
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
          label: "Cumplimiento de hábitos (%)",
          data,
          backgroundColor: "#00b894",
          borderColor: "#00b894",
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

    const chart = new Chart(this.alertsCanvasTarget, {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: "Alertas generadas",
          data,
          borderColor: "#b97a07",
          backgroundColor: "rgba(185, 122, 7, 0.2)",
          fill: true,
          tension: 0.25,
          borderWidth: 3,
          pointBackgroundColor: "#fff",
          pointBorderColor: "#b97a07",
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
          y: { grid: { color: "#e5e5e5" }, ticks: { font: { family: "Inter" } } }
        }
      }
    })

    this.charts.push(chart)
  }

  renderBalanceChart() {
    const labels = Object.keys(this.balanceValue || {})
    const data = Object.values(this.balanceValue || {})

    const chart = new Chart(this.balanceCanvasTarget, {
      type: "bar",
      data: {
        labels,
        datasets: [{
          label: "Balance semanal (L.)",
          data,
          backgroundColor: data.map(v => v >= 0 ? "#00b894" : "#d63031"),
          borderColor: data.map(v => v >= 0 ? "#00b894" : "#d63031"),
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
          y: { grid: { color: "#e5e5e5" }, ticks: { font: { family: "Inter" } } }
        }
      }
    })

    this.charts.push(chart)
  }
}
