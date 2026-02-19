import { Controller } from "@hotwired/stimulus"
import html2canvas from "html2canvas"

export default class extends Controller {
    static targets = ["card"]

    async download(event) {
        const button = event.currentTarget
        const card = this.cardTarget

        // Save original button text
        const originalText = button.innerHTML
        button.innerHTML = "GENERANDO..."
        button.disabled = true

        try {
            // Capture at a fixed width for consistent editorial look across devices
            const canvas = await html2canvas(card, {
                backgroundColor: getComputedStyle(document.body).getPropertyValue('--paper'),
                scale: 2, // Better resolution
                windowWidth: 1000, // Force a wider viewport during capture
                onclone: (clonedDoc) => {
                    const clonedCard = clonedDoc.querySelector('[data-export-target="card"]')
                    if (clonedCard) {
                        clonedCard.style.width = "800px" // Force standard width
                        clonedCard.style.padding = "4rem" // Add consistent border
                        clonedCard.style.margin = "0"
                    }
                }
            })

            const image = canvas.toDataURL("image/png")
            const link = document.createElement("a")
            const date = card.querySelector(".daily-date").innerText.replace("/", "-")

            link.download = `juji-report-${date}.png`
            link.href = image
            link.click()
        } catch (error) {
            console.error("Export failed", error)
            alert("Error al exportar la imagen. Inténtalo de nuevo.")
        } finally {
            button.innerHTML = originalText
            button.disabled = false
        }
    }
}
