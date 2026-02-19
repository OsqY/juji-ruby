import { Controller } from "@hotwired/stimulus"

export default class MenuController extends Controller {
    static targets = ["menu"]

    toggle() {
        this.menuTarget.classList.toggle("menu-active")
        document.body.classList.toggle("no-scroll")
    }

    close() {
        this.menuTarget.classList.remove("menu-active")
        document.body.classList.remove("no-scroll")
    }
}
