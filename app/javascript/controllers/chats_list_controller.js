import { Controller } from "@hotwired/stimulus"

// The chat list is served by a permanent, lazy-loaded frame, so every item
// arrives from the same request (/chats) and the server cannot tell which chat
// is on screen. Compare each item's data-chat-id with the chat in the location
// instead, whenever the main frame or the page navigates.
export default class extends Controller {
  static classes = [ "current" ]
  static targets = [ "item" ]

  connect() {
    this.refresh()
    document.addEventListener("turbo:load", this.refresh)
    document.addEventListener("turbo:frame-load", this.refresh)
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.refresh)
    document.removeEventListener("turbo:frame-load", this.refresh)
  }

  refresh = () => {
    const currentId = this.currentChatId

    for (const item of this.itemTargets) {
      const isCurrent = item.dataset.chatId === currentId

      for (const name of this.currentClasses) {
        item.classList.toggle(name, isCurrent)
      }
    }
  }

  // /chats/42 → "42"; the new chat page (/) → null
  get currentChatId() {
    return window.location.pathname.match(/^\/chats\/(\d+)/)?.[1] ?? null
  }
}
