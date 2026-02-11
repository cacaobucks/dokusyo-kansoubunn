import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "count"]

  connect() {
    this.update()
  }

  update() {
    const count = this.inputTarget.value.length
    this.countTarget.textContent = count
  }
}
