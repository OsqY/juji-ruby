import { Controller } from "@hotwired/stimulus"

export default class ThemeController extends Controller {
    static targets = ["themeSelect", "bratFontSelect"]

    connect() {
        const theme = localStorage.getItem("theme") || "light"
        const bratFont = localStorage.getItem("bratFont") || "helvetica"
        this.applyTheme(theme)
        this.applyBratFont(bratFont)
        this.syncSelectValues(theme, bratFont)
    }

    switch(event) {
        const theme = event.target.value
        this.applyTheme(theme)
        localStorage.setItem("theme", theme)
        this.syncAllThemeSelects(theme)
        this.syncBratFontVisibility(theme)
    }

    applyTheme(theme) {
        document.documentElement.dataset.theme = theme
        this.syncBratFontVisibility(theme)
        this.updateThemeColor(theme)
    }

    updateThemeColor(theme) {
        const meta = document.getElementById('theme-color-meta')
        if (!meta) return
        const paper = getComputedStyle(document.documentElement).getPropertyValue('--paper').trim()
        meta.content = paper || '#FFFFFF'
    }

    switchFont(event) {
        const bratFont = event.target.value
        this.applyBratFont(bratFont)
        localStorage.setItem("bratFont", bratFont)
    }

    applyBratFont(bratFont) {
        document.documentElement.dataset.bratFont = bratFont
    }

    syncSelectValues(theme, bratFont) {
        this.syncAllThemeSelects(theme)
        if (this.hasBratFontSelectTarget) this.bratFontSelectTarget.value = bratFont
        this.syncBratFontVisibility(theme)
    }

    syncAllThemeSelects(theme) {
        document.querySelectorAll('[data-theme-target="themeSelect"]').forEach(select => {
            select.value = theme
        })
    }

    syncBratFontVisibility(theme) {
        if (!this.hasBratFontSelectTarget) return
        this.bratFontSelectTarget.style.display = theme === "brat" ? "inline-block" : "none"
    }
}
