import { Controller } from "@hotwired/stimulus"

// Hides the empty state when a live gift is prepended into the list.
export default class extends Controller {
  static targets = [ "empty", "list" ]

  connect() {
    this.refresh()
    this.observer = new MutationObserver(() => this.refresh())
    this.observer.observe(this.listTarget, { childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  refresh() {
    this.emptyTarget.hidden = Boolean(this.listTarget.querySelector("article"))
  }
}
