import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {
  static values = {
    id: Number,
    token: String,
    userId: String,
    width: Number,
    height: Number,
    bg: String,
    strokes: Array
  }

  static targets = ["canvas", "toolBtn", "colorPicker", "widthSlider", "status"]

  connect() {
    this.setupCanvas()
    this.setupChannel()
    this.tool = "pen"
    this.color = "#000000"
    this.lineWidth = 3
    this.isDrawing = false
    this.currentPoints = []

    this.statusTarget.textContent = "Conectando..."
  }

  disconnect() {
    if (this.channel) {
      this.channel.unsubscribe()
    }
  }

  setupCanvas() {
    this.canvas = this.canvasTarget
    this.ctx = this.canvas.getContext("2d")
    this.canvas.width = this.widthValue
    this.canvas.height = this.heightValue
    this.canvas.style.width = `${this.widthValue}px`
    this.canvas.style.height = `${this.heightValue}px`

    // Fill background
    this.ctx.fillStyle = this.bgValue
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height)

    // Draw existing strokes
    this.strokesValue.forEach(stroke => this.renderStroke(stroke.stroke))
  }

  setupChannel() {
    const params = { whiteboard_id: this.idValue }
    if (this.tokenValue) params.token = this.tokenValue

    this.channel = consumer.subscriptions.create(
      { channel: "WhiteboardChannel", ...params },
      {
        connected: () => {
          this.statusTarget.textContent = "Conectado."
        },
        disconnected: () => {
          this.statusTarget.textContent = "Desconectado."
        },
        received: (data) => {
          this.handleReceived(data)
        }
      }
    )
  }

  handleReceived(data) {
    switch (data.type) {
      case "init":
        // Already drawn from setupCanvas; init is mostly for confirmation
        break
      case "stroke":
        this.renderStroke(data.stroke)
        break
      case "clear":
        this.clearCanvas()
        break
    }
  }

  // Drawing handlers
  startDrawing(event) {
    event.preventDefault()
    this.isDrawing = true
    this.currentPoints = []
    const point = this.getPoint(event)
    this.currentPoints.push(point)
    this.drawPoint(point)
  }

  draw(event) {
    if (!this.isDrawing) return
    event.preventDefault()
    const point = this.getPoint(event)
    this.currentPoints.push(point)
    this.renderLineSegment(this.currentPoints[this.currentPoints.length - 2], point)
  }

  stopDrawing(event) {
    if (!this.isDrawing) return
    this.isDrawing = false

    if (this.currentPoints.length > 1) {
      const strokeData = {
        tool: this.tool,
        color: this.tool === "eraser" ? this.bgValue : this.color,
        width: this.lineWidth,
        points: this.currentPoints
      }
      this.channel.perform("draw", { stroke: strokeData })
    }
  }

  getPoint(event) {
    const rect = this.canvas.getBoundingClientRect()
    const clientX = event.touches ? event.touches[0].clientX : event.clientX
    const clientY = event.touches ? event.touches[0].clientY : event.clientY
    return [
      Math.round(clientX - rect.left),
      Math.round(clientY - rect.top)
    ]
  }

  drawPoint(point) {
    this.ctx.beginPath()
    this.ctx.arc(point[0], point[1], this.lineWidth / 2, 0, Math.PI * 2)
    this.ctx.fillStyle = this.tool === "eraser" ? this.bgValue : this.color
    this.ctx.fill()
  }

  renderLineSegment(from, to) {
    this.ctx.beginPath()
    this.ctx.moveTo(from[0], from[1])
    this.ctx.lineTo(to[0], to[1])
    this.ctx.strokeStyle = this.tool === "eraser" ? this.bgValue : this.color
    this.ctx.lineWidth = this.lineWidth
    this.ctx.lineCap = "round"
    this.ctx.lineJoin = "round"
    this.ctx.stroke()
  }

  renderStroke(strokeData) {
    if (!strokeData.points || strokeData.points.length < 2) return

    this.ctx.beginPath()
    this.ctx.moveTo(strokeData.points[0][0], strokeData.points[0][1])
    for (let i = 1; i < strokeData.points.length; i++) {
      this.ctx.lineTo(strokeData.points[i][0], strokeData.points[i][1])
    }
    this.ctx.strokeStyle = strokeData.color || "#000"
    this.ctx.lineWidth = strokeData.width || 3
    this.ctx.lineCap = "round"
    this.ctx.lineJoin = "round"
    this.ctx.stroke()
  }

  // Tool handlers
  setTool(event) {
    this.tool = event.currentTarget.dataset.tool
    this.toolBtnTargets.forEach(btn => {
      if (btn.dataset.tool === this.tool) {
        btn.style.background = "var(--ink)"
        btn.style.color = "var(--paper)"
      } else {
        btn.style.background = "var(--paper)"
        btn.style.color = "var(--ink)"
      }
    })
  }

  setColor(event) {
    this.color = event.target.value
    this.tool = "pen"
    this.updateToolButtons()
  }

  setWidth(event) {
    this.lineWidth = parseInt(event.target.value, 10)
  }

  updateToolButtons() {
    this.toolBtnTargets.forEach(btn => {
      if (btn.dataset.tool === this.tool) {
        btn.style.background = "var(--ink)"
        btn.style.color = "var(--paper)"
      } else {
        btn.style.background = "var(--paper)"
        btn.style.color = "var(--ink)"
      }
    })
  }

  clear(event) {
    if (confirm("¿Limpiar toda la pizarra?")) {
      this.channel.perform("clear")
    }
  }

  clearCanvas() {
    this.ctx.fillStyle = this.bgValue
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height)
  }

  copyLink(event) {
    const url = `${window.location.origin}/w/${this.tokenValue}`
    navigator.clipboard.writeText(url).then(() => {
      const btn = event.currentTarget
      const original = btn.textContent
      btn.textContent = "¡COPIADO!"
      setTimeout(() => btn.textContent = original, 1500)
    })
  }
}
