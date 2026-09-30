import { Controller } from "@hotwired/stimulus"

// Composer behaviour: the textarea grows with its content, and Enter submits the
// form while Shift+Enter inserts a newline. The controller sits on the form so
// the send button — swapped for a stop button while a response streams — is in
// scope as a target.
export default class extends Controller {
  static targets = ["textarea", "send", "cancel"]

  connect() {
    this.resize()
  }

  // Grow up to the max height set in CSS, then let the textarea scroll.
  resize() {
    this.textareaTarget.style.height = "auto"
    this.textareaTarget.style.height = `${this.textareaTarget.scrollHeight}px`
  }

  submit(event) {
    // Skip IME composition (keyCode 229) so confirming a candidate doesn't send.
    if (event.key !== "Enter" || event.shiftKey || event.isComposing || event.keyCode === 229) return

    // While a response streams the send button gives way to a stop button, so
    // there is no send target to submit — and submitting would cancel instead.
    if (!this.hasSendTarget) return
    if (this.textareaTarget.value.trim() === "") return

    event.preventDefault()

    // Pass the submit button explicitly. Turbo disables (and re-enables) the
    // button named in `SubmitEvent.submitter`, which stays null when
    // `requestSubmit()` is called bare, so the button would never disable.
    this.element.requestSubmit(this.sendTarget)
  }
}
