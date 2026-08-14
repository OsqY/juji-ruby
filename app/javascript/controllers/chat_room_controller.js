import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static values = { roomId: Number }
  static targets = ["input", "messages"]

  connect() {
    this.subscription = createConsumer().subscriptions.create(
      { channel: "ChatRoomChannel", room_id: this.roomIdValue },
      {
        connected: () => {
          this.element.dataset.chatRoomConnected = "true"
        },
        disconnected: () => {
          this.element.dataset.chatRoomConnected = "false"
        },
        rejected: () => {
          this.element.dataset.chatRoomConnected = "false"
        },
        received: (data) => {
          if (data.type === "init") {
            // Historial ya renderizado server-side
            return
          }
          if (data.html) {
            this.appendMessage(data.html)
          }
        }
      }
    )
    this.scrollToBottom()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  submit(event) {
    event.preventDefault()
    const input = this.inputTarget
    const message = input.value.trim()
    if (message.length === 0) return

    if (this.subscription) {
      this.subscription.perform("speak", { message: message })
    }
    input.value = ""
    input.focus()
  }

  appendMessage(html) {
    const container = this.messagesTarget
    const temp = document.createElement("div")
    temp.innerHTML = html
    const messageEl = temp.firstElementChild
    container.appendChild(messageEl)
    this.scrollToBottom()
  }

  scrollToBottom() {
    const container = this.messagesTarget
    container.scrollTop = container.scrollHeight
  }
}
