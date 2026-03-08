import { Controller } from "@hotwired/stimulus"
import { createIcons, Sun, Moon, Palette, Zap } from "lucide"

export default class ThemeController extends Controller {
    static targets = ["select"]

    connect() {
        this.refreshIcons = this.initIcons.bind(this)
        document.addEventListener("turbo:render", this.refreshIcons)
        document.addEventListener("turbo:frame-load", this.refreshIcons)

        const theme = localStorage.getItem("theme") || "light"
        this.applyTheme(theme)
        this.initIcons()

        // Auto-select the radio/option if needed
        const radio = this.element.querySelector(`input[value="${theme}"]`)
        if (radio) radio.checked = true
    }

    disconnect() {
        document.removeEventListener("turbo:render", this.refreshIcons)
        document.removeEventListener("turbo:frame-load", this.refreshIcons)
    }

    initIcons() {
        createIcons({
            icons: {
                Sun,
                Moon,
                Palette,
                Zap
            }
        })
    }

    switch(event) {
        const theme = event.target.value
        this.applyTheme(theme)
        localStorage.setItem("theme", theme)
    }

    applyTheme(theme) {
        document.documentElement.dataset.theme = theme
    }
}
