import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["darkIcon", "lightIcon"]

  connect() {
    this.applyTheme(this.currentTheme)
  }

  toggle() {
    const newTheme = this.currentTheme === "dark" ? "light" : "dark"
    localStorage.setItem("theme", newTheme)
    this.applyTheme(newTheme)
  }

  get currentTheme() {
    const stored = localStorage.getItem("theme")
    if (stored) return stored

    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
  }

  applyTheme(theme) {
    document.documentElement.classList.toggle("dark", theme === "dark")

    if (this.hasDarkIconTarget && this.hasLightIconTarget) {
      this.darkIconTarget.classList.toggle("hidden", theme !== "dark")
      this.lightIconTarget.classList.toggle("hidden", theme === "dark")
    }
  }
}
