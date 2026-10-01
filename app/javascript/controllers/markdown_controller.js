import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"
import DOMPurify from "dompurify"

// Renders the Markdown the server sends as plain text in a hidden source. The
// output is sanitized, since the Markdown is model- or reader-authored.
marked.setOptions({ gfm: true, breaks: true })

// Open links in a new tab; set after sanitizing so the attributes survive.
DOMPurify.addHook("afterSanitizeAttributes", (node) => {
  if (node.tagName === "A" && node.hasAttribute("href")) {
    node.setAttribute("target", "_blank")
    node.setAttribute("rel", "noopener noreferrer")
  }
})

export default class extends Controller {
  static targets = ["source", "output"]

  connect() {
    this.render()

    // Streaming appends to the source and a settled turn replaces it; either way
    // the source changing is the cue to re-render.
    this.observer = new MutationObserver(() => this.render())
    this.observer.observe(this.sourceTarget, { childList: true, characterData: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
    this.observer = null
  }

  render() {
    // textContent reads the source as written; the server escapes the Markdown,
    // so it arrives as text rather than as elements to be parsed.
    this.outputTarget.innerHTML = DOMPurify.sanitize(marked.parse(this.sourceTarget.textContent))
  }
}
