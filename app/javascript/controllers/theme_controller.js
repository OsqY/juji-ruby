import { Controller } from "@hotwired/stimulus"
import { createIcons, Sun, Moon, Palette, Menu, Check, Trash2 } from "lucide"

export default class ThemeController extends Controller {
    static targets = ["select"]

    connect() {
        const theme = localStorage.getItem("theme") || "light"
        this.applyTheme(theme)
        this.initIcons()

        // Auto-select the radio/option if needed
        const radio = this.element.querySelector(`input[value="${theme}"]`)
        if (radio) radio.checked = true
    }

    initIcons() {
        createIcons({
            icons: {
                Sun,
                Moon,
                Palette,
                Menu,
                Check,
                Trash2
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
