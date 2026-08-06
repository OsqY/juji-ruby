import { Controller } from "@hotwired/stimulus"

export default class AwsSidebarController extends Controller {
    static targets = [
        "sidebar", "topbar", "overlay", "toggleIcon",
        "accountMenu", "layout"
    ]

    connect() {
        this.boundCloseAccountMenu = this.closeAccountMenu.bind(this)
        this.boundCloseMobileOnEscape = this.closeMobileOnEscape.bind(this)
        document.addEventListener("click", this.boundCloseAccountMenu)
        document.addEventListener("keydown", this.boundCloseMobileOnEscape)

        const collapsed = localStorage.getItem("awsSidebarCollapsed") === "true"
        if (this.hasLayoutTarget && collapsed) {
            this.layoutTarget.classList.add("is-collapsed")
            this.rotateIcon(true)
        }
    }

    disconnect() {
        document.removeEventListener("click", this.boundCloseAccountMenu)
        document.removeEventListener("keydown", this.boundCloseMobileOnEscape)
    }

    toggleCollapse() {
        if (!this.hasLayoutTarget) return
        const isCollapsed = this.layoutTarget.classList.toggle("is-collapsed")
        localStorage.setItem("awsSidebarCollapsed", isCollapsed)
        this.rotateIcon(isCollapsed)
    }

    rotateIcon(collapsed) {
        if (!this.hasToggleIconTarget) return
        this.toggleIconTarget.style.transform = collapsed ? "rotate(180deg)" : "rotate(0deg)"
        this.toggleIconTarget.style.transition = "transform 0.2s ease"
    }

    toggleMobile() {
        if (!this.hasSidebarTarget) return
        const isOpen = this.sidebarTarget.classList.toggle("is-mobile-open")
        if (this.hasOverlayTarget) {
            this.overlayTarget.classList.toggle("is-visible", isOpen)
        }
        this.setMobileToggleState(isOpen)
    }

    closeMobile() {
        if (!this.hasSidebarTarget) return
        this.sidebarTarget.classList.remove("is-mobile-open")
        if (this.hasOverlayTarget) {
            this.overlayTarget.classList.remove("is-visible")
        }
        this.setMobileToggleState(false)
    }

    closeMobileOnEscape(event) {
        if (event.key === "Escape" && this.hasSidebarTarget && this.sidebarTarget.classList.contains("is-mobile-open")) {
            this.closeMobile()
        }
    }

    setMobileToggleState(isOpen) {
        if (!this.hasTopbarTarget) return
        const toggle = this.topbarTarget.querySelector(".aws-topbar-hamburger")
        toggle?.setAttribute("aria-expanded", String(isOpen))
    }

    toggleAccount(event) {
        event.stopPropagation()
        if (!this.hasAccountMenuTarget) return
        this.accountMenuTarget.classList.toggle("is-open")
    }

    toggleSection(event) {
        const header = event.currentTarget
        const links = header.nextElementSibling
        if (!links) return

        const isOpen = links.style.display !== "none"
        links.style.display = isOpen ? "none" : "block"
        header.setAttribute("aria-expanded", String(!isOpen))

        const chevron = header.querySelector("svg")
        if (chevron) {
            chevron.style.transform = isOpen ? "rotate(-90deg)" : "rotate(0deg)"
            chevron.style.transition = "transform 0.2s ease"
        }
    }

    toggleSectionOnKeydown(event) {
        if (event.key === "Enter" || event.key === " ") {
            event.preventDefault()
            this.toggleSection(event)
        }
    }

    // Close account menu when clicking outside
    closeAccountMenu(event) {
        if (!this.hasAccountMenuTarget) return
        if (!event.target.closest(".aws-topbar-account")) {
            this.accountMenuTarget.classList.remove("is-open")
        }
    }
}
