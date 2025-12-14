import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="desktop-banner"
export default class extends Controller {
  static targets = ["banner"]

  connect() {
    // LocalStorageでバナーを閉じたかチェック
    const dismissed = localStorage.getItem('desktopBannerDismissed')

    // モバイル（768px未満）でバナーが閉じられていない場合のみ表示
    if (window.innerWidth < 768 && !dismissed) {
      this.show()
    }
  }

  dismiss() {
    // バナーを非表示にし、LocalStorageに記録
    this.hide()
    localStorage.setItem('desktopBannerDismissed', 'true')
  }

  show() {
    this.bannerTarget.classList.remove('hidden')
  }

  hide() {
    this.bannerTarget.classList.add('hidden')
  }
}
