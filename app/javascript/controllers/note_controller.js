import { Controller } from "@hotwired/stimulus"

// A donor note is text. Trix accepts dropped and pasted files by default,
// so refuse them before an upload starts.
export default class extends Controller {
  refuseFile(event) {
    event.preventDefault()
  }
}
