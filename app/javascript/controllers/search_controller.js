import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "form"]
  static values = { debounceDelay: 300 }

  connect() {
    this.setupKeyboardShortcut()
    this.selectedIndex = -1
  }

  setupKeyboardShortcut() {
    document.addEventListener("keydown", (e) => {
      // Cmd+K or Ctrl+K to focus search
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault()
        this.inputTarget.focus()
      }
    })
  }

  search(event) {
    clearTimeout(this.searchTimeout)
    this.searchTimeout = setTimeout(() => {
      const query = this.inputTarget.value.trim()
      
      if (query.length === 0) {
        this.resultsTarget.innerHTML = ""
        this.resultsTarget.style.display = 'none'
        this.selectedIndex = -1
        return
      }

      fetch(`/search/results?q=${encodeURIComponent(query)}`, {
        headers: { "Accept": "application/json" }
      })
        .then(response => response.json())
        .then(data => {
          this.displayResults(data, query)
        })
        .catch(error => console.error("Search error:", error))
    }, this.debounceDelayValue)
  }

  displayResults(data, query) {
    const groupedResults = {}
    let totalResults = 0

    Object.entries(data).forEach(([modelType, records]) => {
      if (records.length > 0) {
        groupedResults[modelType] = records.slice(0, 5) // Limit to 5 per type
        totalResults += records.length
      }
    })

    if (totalResults === 0) {
      this.resultsTarget.innerHTML = `
        <div class="search-no-results">
          <p>No se encontraron resultados para "<strong>${this.escapeHtml(query)}</strong>"</p>
        </div>
      `
      this.resultsTarget.style.display = 'block'
      return
    }

    let html = '<div class="search-dropdown">'
    
    Object.entries(groupedResults).forEach(([modelType, records]) => {
      html += `<div class="search-group"><h3 class="search-group-title">${modelType.toUpperCase()}</h3>`
      
      records.forEach((record, index) => {
        html += this.buildResultItem(modelType, record, index)
      })
      
      html += `</div>`
    })

    html += '</div>'
    this.resultsTarget.innerHTML = html
    this.resultsTarget.style.display = 'block'
    this.selectedIndex = -1
  }

  buildResultItem(modelType, record, index) {
    const icons = {
      transactions: "💰",
      daily_reports: "📝",
      projects: "🎯",
      project_tasks: "✓",
      habits: "🌟",
      shopping_items: "🛒",
      budgets: "💳",
      anonymous_forms: "📋"
    }

    const icon = icons[modelType] || "📄"
    const title = this.escapeHtml(record.title || record.name || "Sin título")
    const subtitle = this.escapeHtml(record.subtitle || record.description || "")

    return `
      <a href="${record.url}" class="search-result-item" data-model="${modelType}" data-index="${index}">
        <span class="search-result-icon">${icon}</span>
        <div class="search-result-content">
          <div class="search-result-title">${title}</div>
          ${subtitle ? `<div class="search-result-subtitle">${subtitle}</div>` : ''}
        </div>
      </a>
    `
  }

  handleKeydown(event) {
    const items = this.resultsTarget.querySelectorAll(".search-result-item")
    
    if (items.length === 0) return

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
        this.updateSelection(items)
        break
      
      case "ArrowUp":
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
        this.updateSelection(items)
        break
      
      case "Enter":
        event.preventDefault()
        if (this.selectedIndex >= 0 && this.selectedIndex < items.length) {
          items[this.selectedIndex].click()
        }
        break
      
      case "Escape":
        event.preventDefault()
        this.resultsTarget.innerHTML = ""
        this.selectedIndex = -1
        break
    }
  }

  updateSelection(items) {
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add("is-selected")
        item.scrollIntoView({ block: "nearest" })
      } else {
        item.classList.remove("is-selected")
      }
    })
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  hideResults() {
    // Hide results when input loses focus (with delay to allow click)
    setTimeout(() => {
      if (!this.inputTarget.matches(":focus")) {
        this.resultsTarget.innerHTML = ""
        this.resultsTarget.style.display = 'none'
        this.selectedIndex = -1
      }
    }, 200)
  }
}
