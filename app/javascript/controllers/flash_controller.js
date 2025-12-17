import { Controller } from "@hotwired/stimulus"

// フラッシュメッセージを自動的に非表示にするコントローラ
export default class extends Controller {
  static targets = ["message", "progress"]
  static values = {
    duration: { type: Number, default: 5000 } // デフォルト5秒
  }

  connect() {
    this.startProgress()
    this.timeout = setTimeout(() => {
      this.hide()
    }, this.durationValue)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    if (this.interval) {
      clearInterval(this.interval)
    }
  }

  startProgress() {
    const startTime = Date.now()
    const duration = this.durationValue

    this.interval = setInterval(() => {
      const elapsed = Date.now() - startTime
      const progress = Math.min((elapsed / duration) * 100, 100)

      if (this.hasProgressTarget) {
        this.progressTarget.style.width = `${progress}%`
      }

      if (progress >= 100) {
        clearInterval(this.interval)
      }
    }, 50)
  }

  hide() {
    // フェードアウトアニメーション
    this.element.classList.add("opacity-0", "translate-x-4")

    setTimeout(() => {
      this.element.remove()
    }, 300)
  }

  // クリックで即座に閉じる
  close() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    if (this.interval) {
      clearInterval(this.interval)
    }
    this.hide()
  }
}
