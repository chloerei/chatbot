import { Controller } from "@hotwired/stimulus"

// Fades a toast out after a moment so it doesn't linger over the page.
export default class extends Controller {
  static values = { delay: { type: Number, default: 5000 } }

  connect() {
    this.dismissTimeout = setTimeout(() => this.dismiss(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.dismissTimeout)
    clearTimeout(this.removeTimeout)
  }

  dismiss() {
    // The container owns the opacity transition, so setting this here fades out.
    this.element.style.opacity = "0"
    this.removeTimeout = setTimeout(() => this.element.remove(), 300)
  }
}
