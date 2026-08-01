// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { createIcons, icons } from "lucide"

function initLucide() {
  if (typeof createIcons === "function") {
    createIcons({ icons })
  }
}

document.addEventListener("DOMContentLoaded", initLucide)
document.addEventListener("turbo:load", initLucide)
document.addEventListener("turbo:frame-load", initLucide)
