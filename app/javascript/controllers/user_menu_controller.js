import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown"]

  connect() {
    // ドロップダウン外クリックで閉じる
    this.outsideClickHandler = this.closeOnOutsideClick.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClickHandler)
  }

  toggle(event) {
    event.stopPropagation()
    const isHidden = this.dropdownTarget.classList.contains("hidden")

    if (isHidden) {
      this.dropdownTarget.classList.remove("hidden")
      document.addEventListener("click", this.outsideClickHandler)
    } else {
      this.close()
    }
  }

  close() {
    this.dropdownTarget.classList.add("hidden")
    document.removeEventListener("click", this.outsideClickHandler)
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}
