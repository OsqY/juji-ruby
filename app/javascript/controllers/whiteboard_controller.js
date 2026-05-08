import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"
import rough from "roughjs"

export default class extends Controller {
  static values = {
    id: Number,
    token: String,
    userId: String,
    bg: String,
    strokes: Array
  }

  static targets = ["canvas", "overlay", "toolBtn", "colorPicker", "widthSlider", "status", "zoomDisplay"]

  connect() {
    this.tool = "pen"
    this.color = "#000000"
    this.lineWidth = 3
    this.isDrawing = false
    this.isPanning = false
    this.isSpacePressed = false
    this.currentPoints = []
    this.shapeStart = null
    this.strokes = []
    this.undoStack = []
    this.selectedStrokeIds = new Set()
    this.canDraw = true
    this.clientId = this.generateClientId()

    // Viewport transform
    this.scale = 1
    this.offsetX = 0
    this.offsetY = 0

    this.setupCanvas()
    this.setupChannel()
    this.setupKeyboard()
    this.setupTouch()
    this.setupResize()
    this.updateToolButtons()
    this.updateZoomDisplay()
    this.statusTarget.textContent = "Conectando..."
  }

  disconnect() {
    if (this.channel) {
      this.channel.unsubscribe()
    }
    this.removeTouchListeners()
    this.removeKeyboardListeners()
    window.removeEventListener("resize", this.resizeHandler)
  }

  generateClientId() {
    return "guest_" + Math.random().toString(36).substring(2, 10)
  }

  // ===== Canvas Setup =====

  setupCanvas() {
    this.canvas = this.canvasTarget
    this.ctx = this.canvas.getContext("2d")
    this.roughCanvas = rough.canvas(this.canvas)

    this.resizeCanvas()

    this.redraw()

    // Load existing strokes
    this.strokesValue.forEach(item => {
      const stroke = { stroke: item.stroke, user_id: item.user_id, stroke_id: item.stroke_id, client_id: item.client_id }
      this.strokes.push(stroke)
    })
    this.renderAllStrokes()
  }

  resizeCanvas() {
    const container = this.canvas.parentElement
    const dpr = window.devicePixelRatio || 1
    const w = container.clientWidth
    const h = container.clientHeight

    this.canvas.width = w * dpr
    this.canvas.height = h * dpr
    this.canvas.style.width = `${w}px`
    this.canvas.style.height = `${h}px`
    this.ctx.scale(dpr, dpr)

    if (this.hasOverlayTarget) {
      this.overlay = this.overlayTarget
      this.overlayCtx = this.overlay.getContext("2d")
      this.overlay.width = w * dpr
      this.overlay.height = h * dpr
      this.overlay.style.width = `${w}px`
      this.overlay.style.height = `${h}px`
      this.overlay.style.position = "absolute"
      this.overlay.style.top = "0"
      this.overlay.style.left = "0"
      this.overlay.style.pointerEvents = "none"
      this.overlayCtx.scale(dpr, dpr)
    }

    this.viewWidth = w
    this.viewHeight = h
  }

  setupResize() {
    this.resizeHandler = () => {
      const oldTransform = this.ctx.getTransform()
      this.resizeCanvas()
      this.redraw()
    }
    window.addEventListener("resize", this.resizeHandler)
  }

  // ===== Viewport / Transform =====

  worldToScreen(x, y) {
    return [
      x * this.scale + this.offsetX,
      y * this.scale + this.offsetY
    ]
  }

  screenToWorld(x, y) {
    return [
      (x - this.offsetX) / this.scale,
      (y - this.offsetY) / this.scale
    ]
  }

  setTransform() {
    const dpr = window.devicePixelRatio || 1
    this.ctx.setTransform(dpr * this.scale, 0, 0, dpr * this.scale, dpr * this.offsetX, dpr * this.offsetY)
  }

  resetTransform() {
    const dpr = window.devicePixelRatio || 1
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
  }

  // ===== Grid =====

  drawGrid() {
    const w = this.viewWidth || 1200
    const h = this.viewHeight || 800
    const bg = this.bgValue || "#ffffff"

    this.ctx.fillStyle = bg
    this.ctx.fillRect(-this.offsetX / this.scale, -this.offsetY / this.scale, w / this.scale + 1, h / this.scale + 1)

    const gridColor = this.getGridColor()
    this.ctx.fillStyle = gridColor

    const gridSize = 20
    const startX = Math.floor((-this.offsetX / this.scale) / gridSize) * gridSize
    const startY = Math.floor((-this.offsetY / this.scale) / gridSize) * gridSize
    const endX = startX + (w / this.scale) + gridSize * 2
    const endY = startY + (h / this.scale) + gridSize * 2

    for (let x = startX; x < endX; x += gridSize) {
      for (let y = startY; y < endY; y += gridSize) {
        this.ctx.beginPath()
        this.ctx.arc(x, y, 1.2, 0, Math.PI * 2)
        this.ctx.fill()
      }
    }
  }

  getGridColor() {
    const bg = this.bgValue || "#ffffff"
    const hex = bg.replace("#", "")
    const r = parseInt(hex.substring(0, 2), 16) || 255
    const g = parseInt(hex.substring(2, 4), 16) || 255
    const b = parseInt(hex.substring(4, 6), 16) || 255
    const brightness = (r * 299 + g * 587 + b * 114) / 1000
    return brightness > 128 ? "rgba(0,0,0,0.15)" : "rgba(255,255,255,0.2)"
  }

  // ===== Rendering =====

  redraw() {
    this.resetTransform()
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)
    this.setTransform()
    this.drawGrid()
    this.renderAllStrokes()
    this.renderSelection()
  }

  renderAllStrokes() {
    this.strokes.forEach(s => this.renderStroke(s.stroke))
  }

  renderStroke(strokeData) {
    if (!strokeData) return

    if (strokeData.points && strokeData.points.length >= 2) {
      this.renderFreehand(strokeData)
    } else if (strokeData.shape) {
      this.renderShape(strokeData)
    }
  }

  renderFreehand(strokeData) {
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

  renderShape(strokeData) {
    const options = {
      stroke: strokeData.color || "#000",
      strokeWidth: strokeData.width || 3,
      roughness: 1.5,
      bowing: 1
    }

    switch (strokeData.shape) {
      case "line":
        this.roughCanvas.line(strokeData.x1, strokeData.y1, strokeData.x2, strokeData.y2, options)
        break
      case "arrow": {
        this.roughCanvas.line(strokeData.x1, strokeData.y1, strokeData.x2, strokeData.y2, options)
        this.drawArrowhead(strokeData.x1, strokeData.y1, strokeData.x2, strokeData.y2, strokeData.color || "#000", strokeData.width || 3)
        break
      }
      case "rect":
        this.roughCanvas.rectangle(strokeData.x, strokeData.y, strokeData.w, strokeData.h, options)
        break
      case "circle": {
        const cx = strokeData.x + strokeData.w / 2
        const cy = strokeData.y + strokeData.h / 2
        this.roughCanvas.ellipse(cx, cy, strokeData.w, strokeData.h, options)
        break
      }
    }
  }

  drawArrowhead(x1, y1, x2, y2, color, width) {
    const angle = Math.atan2(y2 - y1, x2 - x1)
    const headLen = Math.max(15, width * 4)
    this.ctx.save()
    this.ctx.strokeStyle = color
    this.ctx.lineWidth = width
    this.ctx.lineCap = "round"
    this.ctx.lineJoin = "round"
    this.ctx.beginPath()
    this.ctx.moveTo(x2, y2)
    this.ctx.lineTo(x2 - headLen * Math.cos(angle - Math.PI / 6), y2 - headLen * Math.sin(angle - Math.PI / 6))
    this.ctx.stroke()
    this.ctx.beginPath()
    this.ctx.moveTo(x2, y2)
    this.ctx.lineTo(x2 - headLen * Math.cos(angle + Math.PI / 6), y2 - headLen * Math.sin(angle + Math.PI / 6))
    this.ctx.stroke()
    this.ctx.restore()
  }

  renderSelection() {
    if (this.selectedStrokeIds.size === 0) return

    const selected = this.strokes.filter(s => this.selectedStrokeIds.has(s.stroke_id))
    selected.forEach(s => {
      const bbox = this.getStrokeBBox(s.stroke)
      if (bbox) {
        this.ctx.save()
        this.ctx.strokeStyle = "#0055FF"
        this.ctx.lineWidth = 2 / this.scale
        this.ctx.setLineDash([6 / this.scale, 4 / this.scale])
        this.ctx.strokeRect(bbox.x - 8, bbox.y - 8, bbox.w + 16, bbox.h + 16)
        this.ctx.setLineDash([])
        this.ctx.restore()
      }
    })
  }

  getStrokeBBox(strokeData) {
    if (!strokeData) return null

    if (strokeData.points && strokeData.points.length > 0) {
      const xs = strokeData.points.map(p => p[0])
      const ys = strokeData.points.map(p => p[1])
      return {
        x: Math.min(...xs),
        y: Math.min(...ys),
        w: Math.max(...xs) - Math.min(...xs),
        h: Math.max(...ys) - Math.min(...ys)
      }
    }

    if (strokeData.shape) {
      switch (strokeData.shape) {
        case "line":
        case "arrow":
          return {
            x: Math.min(strokeData.x1, strokeData.x2),
            y: Math.min(strokeData.y1, strokeData.y2),
            w: Math.abs(strokeData.x2 - strokeData.x1),
            h: Math.abs(strokeData.y2 - strokeData.y1)
          }
        case "rect":
        case "circle":
          return { x: strokeData.x, y: strokeData.y, w: strokeData.w, h: strokeData.h }
      }
    }
    return null
  }

  // ===== Overlay (for shape previews) =====

  clearOverlay() {
    if (this.overlayCtx) {
      const dpr = window.devicePixelRatio || 1
      this.overlayCtx.setTransform(dpr, 0, 0, dpr, 0, 0)
      this.overlayCtx.clearRect(0, 0, this.overlay.width, this.overlay.height)
    }
  }

  previewShapeOnOverlay(start, end) {
    if (!this.overlayCtx) return
    this.clearOverlay()
    const strokeData = this.buildShapeStroke(start, end)
    if (!strokeData) return

    const options = {
      stroke: strokeData.color || "#000",
      strokeWidth: strokeData.width || 3,
      roughness: 1.5,
      bowing: 1
    }

    const roughOverlay = rough.canvas(this.overlay)

    switch (strokeData.shape) {
      case "line":
        roughOverlay.line(strokeData.x1, strokeData.y1, strokeData.x2, strokeData.y2, options)
        break
      case "arrow": {
        roughOverlay.line(strokeData.x1, strokeData.y1, strokeData.x2, strokeData.y2, options)
        this.drawArrowheadOnOverlay(strokeData.x1, strokeData.y1, strokeData.x2, strokeData.y2, strokeData.color || "#000", strokeData.width || 3)
        break
      }
      case "rect":
        roughOverlay.rectangle(strokeData.x, strokeData.y, strokeData.w, strokeData.h, options)
        break
      case "circle": {
        const cx = strokeData.x + strokeData.w / 2
        const cy = strokeData.y + strokeData.h / 2
        roughOverlay.ellipse(cx, cy, strokeData.w, strokeData.h, options)
        break
      }
    }
  }

  drawArrowheadOnOverlay(x1, y1, x2, y2, color, width) {
    const angle = Math.atan2(y2 - y1, x2 - x1)
    const headLen = Math.max(15, width * 4)
    this.overlayCtx.save()
    this.overlayCtx.strokeStyle = color
    this.overlayCtx.lineWidth = width
    this.overlayCtx.lineCap = "round"
    this.overlayCtx.lineJoin = "round"
    this.overlayCtx.beginPath()
    this.overlayCtx.moveTo(x2, y2)
    this.overlayCtx.lineTo(x2 - headLen * Math.cos(angle - Math.PI / 6), y2 - headLen * Math.sin(angle - Math.PI / 6))
    this.overlayCtx.stroke()
    this.overlayCtx.beginPath()
    this.overlayCtx.moveTo(x2, y2)
    this.overlayCtx.lineTo(x2 - headLen * Math.cos(angle + Math.PI / 6), y2 - headLen * Math.sin(angle + Math.PI / 6))
    this.overlayCtx.stroke()
    this.overlayCtx.restore()
  }

  // ===== Coordinate helpers =====

  getPoint(event) {
    const rect = this.canvas.getBoundingClientRect()
    let touch = null
    if (event.changedTouches && event.changedTouches.length > 0) {
      touch = event.changedTouches[0]
    } else if (event.touches && event.touches.length > 0) {
      touch = event.touches[0]
    }
    const clientX = touch ? touch.clientX : event.clientX
    const clientY = touch ? touch.clientY : event.clientY
    return this.screenToWorld(clientX - rect.left, clientY - rect.top)
  }

  getScreenPoint(event) {
    const rect = this.canvas.getBoundingClientRect()
    let touch = null
    if (event.changedTouches && event.changedTouches.length > 0) {
      touch = event.changedTouches[0]
    } else if (event.touches && event.touches.length > 0) {
      touch = event.touches[0]
    }
    const clientX = touch ? touch.clientX : event.clientX
    const clientY = touch ? touch.clientY : event.clientY
    return [clientX - rect.left, clientY - rect.top]
  }

  // ===== ActionCable =====

  setupChannel() {
    const params = { whiteboard_id: this.idValue }
    if (this.tokenValue) params.token = this.tokenValue

    this.channel = createConsumer().subscriptions.create(
      { channel: "WhiteboardChannel", ...params },
      {
        connected: () => {
          this.statusTarget.textContent = "Conectado."
          this.canDraw = true
        },
        disconnected: () => {
          this.statusTarget.textContent = "Desconectado."
          this.canDraw = false
        },
        rejected: () => {
          this.statusTarget.textContent = "Acceso denegado."
          this.canDraw = false
        },
        received: (data) => {
          this.handleReceived(data)
        }
      }
    )
  }

  handleReceived(data) {
    switch (data.type) {
      case "init": {
        // Load strokes from server on connect (for late joiners)
        data.strokes.forEach(item => {
          const exists = this.strokes.some(s => s.stroke_id === item.stroke_id)
          if (!exists) {
            const stroke = { stroke: item.stroke, user_id: item.user_id, stroke_id: item.stroke_id }
            this.strokes.push(stroke)
          }
        })
        this.redraw()
        break
      }
      case "stroke": {
        const exists = this.strokes.some(s => s.stroke_id === data.stroke_id)
        if (!exists) {
          const stroke = { stroke: data.stroke, user_id: data.user_id, stroke_id: data.stroke_id }
          this.strokes.push(stroke)
          this.renderStroke(data.stroke)
        }
        break
      }
      case "undo": {
        this.strokes = this.strokes.filter(s => s.stroke_id !== data.stroke_id)
        this.redraw()
        break
      }
      case "clear":
        this.strokes = []
        this.undoStack = []
        this.selectedStrokeIds.clear()
        this.redraw()
        break
      case "delete": {
        data.stroke_ids.forEach(id => {
          this.strokes = this.strokes.filter(s => s.stroke_id !== id)
          this.selectedStrokeIds.delete(id)
        })
        this.redraw()
        break
      }
    }
  }

  // ===== Input Handlers =====

  startDrawing(event) {
    if (!this.canDraw) return
    if (event.button === 1 || (this.isSpacePressed && event.button === 0)) {
      // Middle mouse or space+click = pan
      this.isPanning = true
      this.panStart = this.getScreenPoint(event)
      this.panOffsetStart = [this.offsetX, this.offsetY]
      this.canvas.style.cursor = "grabbing"
      event.preventDefault()
      return
    }
    if (event.button !== 0) return

    event.preventDefault()
    this.isDrawing = true
    const point = this.getPoint(event)

    if (this.tool === "pen" || this.tool === "eraser") {
      this.currentPoints = [point]
      this.drawPoint(point)
    } else if (this.tool === "select") {
      this.isDrawing = false
      this.handleSelect(point)
    } else {
      this.shapeStart = point
    }
  }

  draw(event) {
    if (this.isPanning) {
      event.preventDefault()
      const point = this.getScreenPoint(event)
      this.offsetX = this.panOffsetStart[0] + (point[0] - this.panStart[0])
      this.offsetY = this.panOffsetStart[1] + (point[1] - this.panStart[1])
      this.redraw()
      return
    }

    if (!this.isDrawing) return
    event.preventDefault()
    const point = this.getPoint(event)

    if (this.tool === "pen" || this.tool === "eraser") {
      this.currentPoints.push(point)
      this.renderLineSegment(this.currentPoints[this.currentPoints.length - 2], point)
    } else if (this.tool !== "select") {
      this.previewShapeOnOverlay(this.shapeStart, point)
    }
  }

  stopDrawing(event) {
    if (this.isPanning) {
      this.isPanning = false
      this.canvas.style.cursor = this.tool === "select" ? "default" : "crosshair"
      return
    }

    if (!this.isDrawing) return
    this.isDrawing = false
    event.preventDefault()

    if (this.tool === "pen" || this.tool === "eraser") {
      if (this.currentPoints.length > 1) {
        const strokeData = {
          tool: this.tool,
          color: this.tool === "eraser" ? this.bgValue : this.color,
          width: this.lineWidth,
          points: this.currentPoints
        }
        const stroke = { stroke: strokeData, user_id: this.userIdValue, stroke_id: null, client_id: this.clientId }
        this.strokes.push(stroke)
        this.undoStack = []
        this.channel.perform("draw", { stroke: strokeData, client_id: this.clientId })
      }
    } else if (this.shapeStart) {
      const endPoint = this.getPoint(event)
      this.clearOverlay()
      const strokeData = this.buildShapeStroke(this.shapeStart, endPoint)
      if (strokeData) {
        const stroke = { stroke: strokeData, user_id: this.userIdValue, stroke_id: null, client_id: this.clientId }
        this.strokes.push(stroke)
        this.undoStack = []
        this.renderStroke(strokeData)
        this.channel.perform("draw", { stroke: strokeData, client_id: this.clientId })
      }
      this.shapeStart = null
    }
  }

  // ===== Zoom =====

  zoom(event) {
    event.preventDefault()
    const rect = this.canvas.getBoundingClientRect()
    const mouseX = event.clientX - rect.left
    const mouseY = event.clientY - rect.top

    const worldBefore = this.screenToWorld(mouseX, mouseY)
    const delta = event.deltaY > 0 ? 0.9 : 1.1
    const newScale = Math.max(0.1, Math.min(5, this.scale * delta))

    this.scale = newScale
    this.offsetX = mouseX - worldBefore[0] * this.scale
    this.offsetY = mouseY - worldBefore[1] * this.scale

    this.updateZoomDisplay()
    this.redraw()
  }

  resetZoom() {
    this.scale = 1
    this.offsetX = 0
    this.offsetY = 0
    this.updateZoomDisplay()
    this.redraw()
  }

  updateZoomDisplay() {
    if (this.hasZoomDisplayTarget) {
      this.zoomDisplayTarget.textContent = `${Math.round(this.scale * 100)}%`
    }
  }

  // ===== Selection =====

  handleSelect(point) {
    const threshold = 10 / this.scale
    let found = null

    // Search from newest to oldest
    for (let i = this.strokes.length - 1; i >= 0; i--) {
      const s = this.strokes[i]
      if (this.pointNearStroke(point, s.stroke, threshold)) {
        found = s
        break
      }
    }

    if (found) {
      if (this.selectedStrokeIds.has(found.stroke_id)) {
        this.selectedStrokeIds.delete(found.stroke_id)
      } else {
        // If not holding shift, clear previous selection
        if (!this.isShiftPressed) {
          this.selectedStrokeIds.clear()
        }
        this.selectedStrokeIds.add(found.stroke_id)
      }
    } else {
      this.selectedStrokeIds.clear()
    }
    this.redraw()
  }

  pointNearStroke(point, strokeData, threshold) {
    if (!strokeData) return false

    if (strokeData.points && strokeData.points.length > 0) {
      for (let i = 0; i < strokeData.points.length - 1; i++) {
        if (this.pointToSegmentDistance(point, strokeData.points[i], strokeData.points[i + 1]) < threshold) {
          return true
        }
      }
      // Check distance to last point
      const last = strokeData.points[strokeData.points.length - 1]
      const dx = point[0] - last[0]
      const dy = point[1] - last[1]
      if (Math.sqrt(dx * dx + dy * dy) < threshold) return true
    }

    if (strokeData.shape) {
      const bbox = this.getStrokeBBox(strokeData)
      if (bbox) {
        return point[0] >= bbox.x - threshold && point[0] <= bbox.x + bbox.w + threshold &&
               point[1] >= bbox.y - threshold && point[1] <= bbox.y + bbox.h + threshold
      }
    }

    return false
  }

  pointToSegmentDistance(p, v, w) {
    const l2 = (v[0] - w[0]) ** 2 + (v[1] - w[1]) ** 2
    if (l2 === 0) return Math.sqrt((p[0] - v[0]) ** 2 + (p[1] - v[1]) ** 2)
    let t = ((p[0] - v[0]) * (w[0] - v[0]) + (p[1] - v[1]) * (w[1] - v[1])) / l2
    t = Math.max(0, Math.min(1, t))
    return Math.sqrt((p[0] - (v[0] + t * (w[0] - v[0]))) ** 2 + (p[1] - (v[1] + t * (w[1] - v[1]))) ** 2)
  }

  deleteSelected() {
    if (this.selectedStrokeIds.size === 0) return
    const ids = Array.from(this.selectedStrokeIds).filter(id => id !== null)
    if (ids.length === 0) return

    this.strokes = this.strokes.filter(s => !this.selectedStrokeIds.has(s.stroke_id))
    this.selectedStrokeIds.clear()
    this.redraw()
    this.channel.perform("delete", { stroke_ids: ids })
  }

  // ===== Eraser =====

  eraseStrokesAlongPath(points) {
    if (points.length < 2) return
    const threshold = Math.max(10, this.lineWidth * 2)
    const toDelete = []

    this.strokes.forEach(s => {
      if (this.strokeIntersectsPath(s.stroke, points, threshold)) {
        toDelete.push(s.stroke_id)
      }
    })

    if (toDelete.length > 0) {
      this.strokes = this.strokes.filter(s => !toDelete.includes(s.stroke_id))
      this.selectedStrokeIds = new Set([...this.selectedStrokeIds].filter(id => !toDelete.includes(id)))
      this.redraw()
      this.channel.perform("delete", { stroke_ids: toDelete.filter(id => id !== null) })
    }
  }

  strokeIntersectsPath(strokeData, pathPoints, threshold) {
    if (!strokeData || pathPoints.length < 2) return false

    for (let i = 0; i < pathPoints.length - 1; i++) {
      const p1 = pathPoints[i]
      const p2 = pathPoints[i + 1]

      if (strokeData.points && strokeData.points.length > 0) {
        for (let j = 0; j < strokeData.points.length - 1; j++) {
          if (this.segmentsIntersect(p1, p2, strokeData.points[j], strokeData.points[j + 1], threshold)) {
            return true
          }
        }
      }

      if (strokeData.shape) {
        const bbox = this.getStrokeBBox(strokeData)
        if (bbox) {
          // Simple bbox intersection check for shapes
          const minX = Math.min(p1[0], p2[0]) - threshold
          const maxX = Math.max(p1[0], p2[0]) + threshold
          const minY = Math.min(p1[1], p2[1]) - threshold
          const maxY = Math.max(p1[1], p2[1]) + threshold
          if (minX < bbox.x + bbox.w && maxX > bbox.x && minY < bbox.y + bbox.h && maxY > bbox.y) {
            return true
          }
        }
      }
    }
    return false
  }

  segmentsIntersect(p1, p2, p3, p4, threshold) {
    // Check if two line segments are within threshold distance
    const dist = this.pointToSegmentDistance(p1, p3, p4)
    if (dist < threshold) return true
    const dist2 = this.pointToSegmentDistance(p2, p3, p4)
    if (dist2 < threshold) return true
    const dist3 = this.pointToSegmentDistance(p3, p1, p2)
    if (dist3 < threshold) return true
    return false
  }

  // ===== Shape builders =====

  buildShapeStroke(start, end) {
    const base = {
      tool: this.tool,
      color: this.color,
      width: this.lineWidth
    }

    switch (this.tool) {
      case "line":
        return { ...base, shape: "line", x1: start[0], y1: start[1], x2: end[0], y2: end[1] }
      case "arrow":
        return { ...base, shape: "arrow", x1: start[0], y1: start[1], x2: end[0], y2: end[1] }
      case "rect": {
        const x = Math.min(start[0], end[0])
        const y = Math.min(start[1], end[1])
        const w = Math.abs(end[0] - start[0])
        const h = Math.abs(end[1] - start[1])
        return { ...base, shape: "rect", x, y, w, h }
      }
      case "circle": {
        const x = Math.min(start[0], end[0])
        const y = Math.min(start[1], end[1])
        const w = Math.abs(end[0] - start[0])
        const h = Math.abs(end[1] - start[1])
        return { ...base, shape: "circle", x, y, w, h }
      }
      default:
        return null
    }
  }

  // ===== Point / Segment rendering =====

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

  // ===== Tool handlers =====

  setTool(event) {
    this.tool = event.currentTarget.dataset.tool
    this.updateToolButtons()
    this.canvas.style.cursor = this.tool === "select" ? "default" : "crosshair"
    this.clearOverlay()
    this.shapeStart = null
  }

  setColor(event) {
    this.color = event.target.value
    if (this.tool === "eraser") {
      this.tool = "pen"
      this.updateToolButtons()
    }
  }

  setWidth(event) {
    this.lineWidth = parseInt(event.target.value, 10)
  }

  updateToolButtons() {
    this.toolBtnTargets.forEach(btn => {
      const isActive = btn.dataset.tool === this.tool
      btn.style.background = isActive ? "var(--ink)" : "var(--paper)"
      btn.style.color = isActive ? "var(--paper)" : "var(--ink)"
    })
  }

  // ===== Undo / Redo =====

  undo() {
    if (this.strokes.length === 0) return
    const last = this.strokes[this.strokes.length - 1]
    // Only undo our own strokes
    const isMine = last.user_id === this.userIdValue || last.client_id === this.clientId
    if (!isMine) return

    this.strokes.pop()
    this.undoStack.push(last)
    this.redraw()
    if (last.stroke_id) {
      this.channel.perform("undo", { stroke_id: last.stroke_id })
    }
  }

  redo() {
    if (this.undoStack.length === 0) return
    const stroke = this.undoStack.pop()
    this.strokes.push(stroke)
    this.redraw()
    this.channel.perform("draw", { stroke: stroke.stroke, client_id: this.clientId })
  }

  // ===== Clear =====

  clear(event) {
    if (confirm("¿Limpiar toda la pizarra?")) {
      this.channel.perform("clear")
    }
  }

  // ===== Export =====

  exportPng() {
    // Render at 1x scale for export
    const oldScale = this.scale
    const oldOffsetX = this.offsetX
    const oldOffsetY = this.offsetY
    this.scale = 1
    this.offsetX = 0
    this.offsetY = 0
    this.redraw()

    const link = document.createElement("a")
    link.download = `pizarra-${this.idValue}.png`
    link.href = this.canvas.toDataURL("image/png")
    link.click()

    this.scale = oldScale
    this.offsetX = oldOffsetX
    this.offsetY = oldOffsetY
    this.redraw()
  }

  // ===== Copy link =====

  copyLink(event) {
    const url = `${window.location.origin}/w/${this.tokenValue}`
    navigator.clipboard.writeText(url).then(() => {
      const btn = event.currentTarget
      const original = btn.textContent
      btn.textContent = "¡COPIADO!"
      setTimeout(() => btn.textContent = original, 1500)
    })
  }

  // ===== Keyboard =====

  setupKeyboard() {
    this.keydownHandler = this.handleKeyDown.bind(this)
    this.keyupHandler = this.handleKeyUp.bind(this)
    document.addEventListener("keydown", this.keydownHandler)
    document.addEventListener("keyup", this.keyupHandler)
  }

  removeKeyboardListeners() {
    document.removeEventListener("keydown", this.keydownHandler)
    document.removeEventListener("keyup", this.keyupHandler)
  }

  handleKeyDown(event) {
    if (event.key === " ") {
      this.isSpacePressed = true
      if (!this.isDrawing) {
        this.canvas.style.cursor = "grab"
      }
    }
    if (event.key === "Shift") {
      this.isShiftPressed = true
    }
    if (event.key === "Delete" || event.key === "Backspace") {
      this.deleteSelected()
    }
    if ((event.ctrlKey || event.metaKey) && event.key === "z") {
      event.preventDefault()
      if (event.shiftKey) {
        this.redo()
      } else {
        this.undo()
      }
    }
    if (event.key === "1") this.activateTool("pen")
    if (event.key === "2") this.activateTool("line")
    if (event.key === "3") this.activateTool("arrow")
    if (event.key === "4") this.activateTool("rect")
    if (event.key === "5") this.activateTool("circle")
    if (event.key === "6") this.activateTool("eraser")
    if (event.key === "7" || event.key === "v") this.activateTool("select")
  }

  handleKeyUp(event) {
    if (event.key === " ") {
      this.isSpacePressed = false
      if (!this.isPanning) {
        this.canvas.style.cursor = this.tool === "select" ? "default" : "crosshair"
      }
    }
    if (event.key === "Shift") {
      this.isShiftPressed = false
    }
  }

  activateTool(toolName) {
    this.tool = toolName
    this.updateToolButtons()
    this.canvas.style.cursor = this.tool === "select" ? "default" : "crosshair"
    this.clearOverlay()
    this.shapeStart = null
  }

  // ===== Touch Support =====

  setupTouch() {
    this.touchStartHandler = (e) => {
      if (e.touches.length === 1) {
        this.startDrawing(e)
      }
    }
    this.touchMoveHandler = (e) => {
      if (e.touches.length === 1) {
        this.draw(e)
      }
    }
    this.touchEndHandler = (e) => {
      this.stopDrawing(e)
    }

    this.canvas.addEventListener("touchstart", this.touchStartHandler, { passive: false })
    this.canvas.addEventListener("touchmove", this.touchMoveHandler, { passive: false })
    this.canvas.addEventListener("touchend", this.touchEndHandler, { passive: false })
    this.canvas.addEventListener("touchcancel", this.touchEndHandler, { passive: false })
  }

  removeTouchListeners() {
    this.canvas.removeEventListener("touchstart", this.touchStartHandler)
    this.canvas.removeEventListener("touchmove", this.touchMoveHandler)
    this.canvas.removeEventListener("touchend", this.touchEndHandler)
    this.canvas.removeEventListener("touchcancel", this.touchEndHandler)
  }
}
