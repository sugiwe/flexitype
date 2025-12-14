import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sidebar"
export default class extends Controller {
  static targets = ["menu", "overlay"]

  connect() {
    // 初期状態はtranslate-x-fullで設定済み（モバイルでは右に隠れている）
  }

  toggle() {
    const isOpen = !this.menuTarget.classList.contains("translate-x-full")
    if (isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  close() {
    // 右にスライドして隠す（モバイル）
    this.menuTarget.classList.add("translate-x-full")
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("hidden")
    }
  }

  open() {
    // 左にスライドして表示（モバイル）
    this.menuTarget.classList.remove("translate-x-full")
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("hidden")
    }
  }
}
