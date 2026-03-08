import { Controller } from "@hotwired/stimulus"
import html2canvas from "html2canvas"

export default class extends Controller {
    static targets = ["card"]

    async download(event) {
        const button = event.currentTarget
        const card = this.cardTarget
        const exportPadding = 28
        const paperColor = getComputedStyle(document.body).getPropertyValue("--paper").trim() || "#ffffff"

        const originalText = button.innerHTML
        button.innerHTML = "GENERANDO..."
        button.disabled = true

        let captureHost = null

        try {
            const exportWidth = Math.ceil(card.scrollWidth)

            // Build an offscreen capture host to add extra breathing room in width/height.
            captureHost = document.createElement("div")
            captureHost.style.position = "fixed"
            captureHost.style.left = "-10000px"
            captureHost.style.top = "0"
            captureHost.style.padding = `${exportPadding}px`
            captureHost.style.background = paperColor
            captureHost.style.zIndex = "-1"
            captureHost.style.boxSizing = "border-box"

            const cardClone = card.cloneNode(true)
            cardClone.style.maxWidth = "none"
            cardClone.style.width = `${exportWidth}px`
            cardClone.style.margin = "0"
            cardClone.style.boxSizing = "border-box"
            cardClone.style.overflow = "visible"

            captureHost.appendChild(cardClone)
            document.body.appendChild(captureHost)

            const canvas = await html2canvas(captureHost, {
                backgroundColor: paperColor,
                scale: 2,
                useCORS: true,
                width: Math.ceil(captureHost.scrollWidth),
                height: Math.ceil(captureHost.scrollHeight),
                windowWidth: Math.ceil(captureHost.scrollWidth),
                windowHeight: Math.ceil(captureHost.scrollHeight),
                scrollX: 0,
                scrollY: 0
            })

            const image = canvas.toDataURL("image/png")
            const link = document.createElement("a")
            const date = (card.querySelector(".daily-date")?.innerText || "daily").replace("/", "-")

            link.download = `juji-report-${date}.png`
            link.href = image
            link.click()
        } catch (error) {
            console.error("Export failed", error)
            alert("Error al exportar la imagen. Intentalo de nuevo.")
        } finally {
            if (captureHost) captureHost.remove()
            button.innerHTML = originalText
            button.disabled = false
    }
    }
}
