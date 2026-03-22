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
        this.syncBratFontVisibility(theme)
    }

    applyTheme(theme) {
        document.documentElement.dataset.theme = theme
        this.syncBratFontVisibility(theme)
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
        if (this.hasThemeSelectTarget) this.themeSelectTarget.value = theme
        if (this.hasBratFontSelectTarget) this.bratFontSelectTarget.value = bratFont
        this.syncBratFontVisibility(theme)
    }

    syncBratFontVisibility(theme) {
        if (!this.hasBratFontSelectTarget) return
        this.bratFontSelectTarget.style.display = theme === "brat" ? "inline-block" : "none"
    }
}
