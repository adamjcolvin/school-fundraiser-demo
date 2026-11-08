import { Controller } from "@hotwired/stimulus"

// Grows the bar to the funded share of the goal. A Turbo Stream
// replacement reconnects the controller, so a new gift animates the bar
// again.
export default class extends Controller {
  static targets = [ "bar" ]
  static values = { percent: Number }

  connect() {
    const width = `${this.percentValue}%`
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches

    if (reduce) {
      this.barTarget.style.width = width
      return
    }

    this.barTarget.style.width = "0%"
    requestAnimationFrame(() => {
      this.barTarget.style.width = width
    })
  }
}
