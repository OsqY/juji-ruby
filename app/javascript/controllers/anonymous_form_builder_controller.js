import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template", "question"]

  connect() {
    if (this.questionTargets.length === 0) {
      this.addQuestion()
    }

    this.reindex()
    this.refreshOptionPanels()
  }

  addQuestion(event) {
    if (event) {
      event.preventDefault()
    }

    const html = this.templateTarget.innerHTML.replace(/__INDEX__/g, String(Date.now()))
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.reindex()
    this.refreshOptionPanels()
  }

  removeQuestion(event) {
    event.preventDefault()
    const card = event.target.closest("[data-anonymous-form-builder-target='question']")

    if (card) {
      card.remove()
    }

    if (this.questionTargets.length === 0) {
      this.addQuestion()
      return
    }

    this.reindex()
  }

  toggleType(event) {
    const select = event.target
    const card = select.closest("[data-anonymous-form-builder-target='question']")
    this.refreshOptionPanel(card)
  }

  reindex() {
    this.questionTargets.forEach((question, index) => {
      const positionInput = question.querySelector("[data-question-position]")
      if (positionInput) {
        positionInput.value = String(index)
      }

      question.querySelectorAll("[name]").forEach((input) => {
        input.name = input.name.replace(/\[questions_attributes\]\[[^\]]+\]/, `[questions_attributes][${index}]`)
      })
    })
  }

  refreshOptionPanels() {
    this.questionTargets.forEach((question) => this.refreshOptionPanel(question))
  }

  refreshOptionPanel(card) {
    if (!card) {
      return
    }

    const typeSelect = card.querySelector("[data-question-type]")
    const optionsPanel = card.querySelector("[data-question-options]")

    if (!typeSelect || !optionsPanel) {
      return
    }

    if (typeSelect.value === "free_text") {
      optionsPanel.style.display = "none"
    } else {
      optionsPanel.style.display = "block"
    }
  }
}
