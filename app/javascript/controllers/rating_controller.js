import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["star", "input", "form"]
  static values = { current: Number }

  connect() {
    const input = this.inputTarget
    this.currentValue = parseInt(input.value) || 0
    this.highlightStars(this.currentValue)
  }

  hover(event) {
    const rating = parseInt(event.currentTarget.dataset.rating)
    this.highlightStars(rating)
  }

  leave() {
    this.highlightStars(this.currentValue)
  }

  select(event) {
    const rating = parseInt(event.currentTarget.dataset.rating)
    this.currentValue = rating
    this.inputTarget.value = rating
    this.highlightStars(rating)

    // Submit the form
    this.formTarget.requestSubmit()
  }

  highlightStars(rating) {
    this.starTargets.forEach((star) => {
      const starRating = parseInt(star.dataset.rating)
      if (starRating <= rating) {
        star.classList.remove("star-empty")
        star.classList.add("star-filled")
      } else {
        star.classList.remove("star-filled")
        star.classList.add("star-empty")
      }
    })
  }
}
