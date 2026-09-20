import { Controller } from "@hotwired/stimulus"

// Composer textarea behaviour: it grows with its content, and Enter submits the
// form while Shift+Enter inserts a newline.
export default class extends Controller {
  connect() {
    this.resize()
  }

  // Grow up to the max height set in CSS, then let the textarea scroll.
  resize() {
    this.element.style.height = "auto"
    this.element.style.height = `${this.element.scrollHeight}px`
  }

  submit(event) {
    // Skip IME composition (keyCode 229) so confirming a candidate doesn't send.
    if (event.key !== "Enter" || event.shiftKey || event.isComposing || event.keyCode === 229) return
    if (this.element.value.trim() === "") return

    event.preventDefault()
    this.element.form?.requestSubmit()
  }
}
