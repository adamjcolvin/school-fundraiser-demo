import { Controller } from "@hotwired/stimulus"

// Preset amounts write into the dollar field. Typing a custom amount
// clears the highlight when it no longer matches a preset.
export default class extends Controller {
  static targets = [ "amount", "button" ]

  connect() {
    this.sync()
  }

  choose(event) {
    this.amountTarget.value = event.currentTarget.dataset.amount
    this.sync()
    this.amountTarget.focus()
  }

  sync() {
    const current = this.normalize(this.amountTarget.value)

    this.buttonTargets.forEach((button) => {
      const selected = button.dataset.amount === current
      button.classList.toggle("is-selected", selected)
      button.setAttribute("aria-pressed", selected ? "true" : "false")
    })
  }

  normalize(value) {
    const trimmed = String(value).trim().replace(/[$,]/g, "")
    if (trimmed === "") return ""

    const amount = Number(trimmed)
    if (!Number.isFinite(amount)) return trimmed

    return String(amount)
  }
}
