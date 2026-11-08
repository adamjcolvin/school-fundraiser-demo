import { Controller } from "@hotwired/stimulus"

// Changes the submit label once the browser accepts the form.
// The button stays enabled until the request leaves, so the click
// is not cancelled.
export default class extends Controller {
  static targets = [ "submit" ]

  start() {
    this.element.setAttribute("aria-busy", "true")
    this.submitTarget.textContent = "Recording gift"
  }
}
