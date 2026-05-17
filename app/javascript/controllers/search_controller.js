import { Controller } from "@hotwire/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "form"]
  static values = { debounceDelay: 300, searchPath: String, userId: String }

  connect() {
    this.setupKeyboardShortcut()
    this.selectedIndex = -1
    this.MAX_HISTORY = 10
    this.STORAGE_KEY = `search_history_${this.userIdValue || "guest"}`
    this.i18n = {
      recentSearches: this.element.dataset.i18nRecentSearches || "Busquedas Recientes",
      noResults: this.element.dataset.i18nNoResults || "No se encontraron resultados para",
      untitled: this.element.dataset.i18nUntitled || "Sin titulo"
    }
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
        // Show search history if available
        this.showSearchHistory()
        return
      }

      fetch(`${this.searchPathValue || "/search/results"}?q=${encodeURIComponent(query)}`, {
        headers: { "Accept": "application/json" }
      })
        .then(response => response.json())
        .then(data => {
          this.displayResults(data, query)
        })
        .catch(error => console.error("Search error:", error))
    }, this.debounceDelayValue)
  }

  showSearchHistory() {
    const history = this.getSearchHistory()
    
    if (history.length === 0) {
      this.resultsTarget.innerHTML = ""
      this.resultsTarget.style.display = 'none'
      return
    }

    let html = '<div class="search-dropdown"><div class="search-group">'
      html += `<h3 class="search-group-title">${this.i18n.recentSearches}</h3>`
    
    history.forEach((query, index) => {
      html += `
        <a href="/search?q=${encodeURIComponent(query)}" class="search-history-item">
          <span class="search-result-icon">H</span>
          <div class="search-result-content">
            <div class="search-result-title">${this.escapeHtml(query)}</div>
          </div>
        </a>
      `
    })
    
    html += '</div></div>'
    this.resultsTarget.innerHTML = html
    this.resultsTarget.style.display = 'block'
    this.selectedIndex = -1
  }

  displayResults(data, query) {
    const resultsData = data.results || {}
    const groupedResults = {}
    let totalResults = 0

    Object.entries(resultsData).forEach(([modelType, records]) => {
      if (Array.isArray(records) && records.length > 0) {
        groupedResults[modelType] = records.slice(0, 5) // Limit to 5 per type
        totalResults += records.length
      }
    })

    // Add search to history after successful search
    this.addToSearchHistory(query)

    if (totalResults === 0) {
      this.resultsTarget.innerHTML = `
        <div class="search-no-results">
          <p>${this.i18n.noResults} "<strong>${this.escapeHtml(query)}</strong>"</p>
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
      transactions: "TX",
      daily_reports: "RP",
      projects: "PJ",
      project_tasks: "TK",
      habits: "HB",
      shopping_items: "CP",
      budgets: "BG",
      anonymous_forms: "FM"
    }

    const icon = icons[modelType] || "DOC"
    const title = this.escapeHtml(record.title || record.name || this.i18n.untitled)
    const subtitle = this.escapeHtml(record.subtitle || record.description || "")

    return `
      <a href="${record.url}" class="search-result-item" data-model="${modelType}" data-index="${index}">
        <span class="search-result-icon" aria-hidden="true">${icon}</span>
        <div class="search-result-content">
          <div class="search-result-title">${title}</div>
          ${subtitle ? `<div class="search-result-subtitle">${subtitle}</div>` : ''}
        </div>
      </a>
    `
  }

  handleKeydown(event) {
    const items = this.resultsTarget.querySelectorAll(".search-result-item, .search-history-item")
    
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
        this.resultsTarget.style.display = 'none'
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

  // Search history management
  getSearchHistory() {
    const stored = localStorage.getItem(this.STORAGE_KEY)
    return stored ? JSON.parse(stored) : []
  }

  addToSearchHistory(query) {
    let history = this.getSearchHistory()
    
    // Remove if already exists (to put it at the front)
    history = history.filter(q => q.toLowerCase() !== query.toLowerCase())
    
    // Add to front
    history.unshift(query)
    
    // Limit to MAX_HISTORY items
    history = history.slice(0, this.MAX_HISTORY)
    
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(history))
  }

  clearSearchHistory() {
    localStorage.removeItem(this.STORAGE_KEY)
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.style.display = 'none'
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
