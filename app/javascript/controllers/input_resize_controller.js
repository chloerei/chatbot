import { Controller } from "@hotwired/stimulus"

// Grows a textarea with its content, up to the max height set in CSS.
export default class extends Controller {
  connect() {
    this.resize()
  }

  resize() {
    this.element.style.height = "auto"
    this.element.style.height = `${this.element.scrollHeight}px`
  }
}
