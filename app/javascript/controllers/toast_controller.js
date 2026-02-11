import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    duration: { type: Number, default: 5000 }
  }

  connect() {
    this.show()
  }

  show() {
    this.element.classList.add("animate-fade-in")

    if (this.durationValue > 0) {
      this.timeout = setTimeout(() => {
        this.dismiss()
      }, this.durationValue)
    }
  }

  dismiss() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    this.element.classList.add("opacity-0", "transition-opacity", "duration-300")

    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
