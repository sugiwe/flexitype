import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "tab", "content" ]

  connect() {
    // Turbo Frameのロード開始/終了イベントをリッスン
    this.contentTarget.addEventListener("turbo:frame-load", this.hideLoading.bind(this))
    this.contentTarget.addEventListener("turbo:before-frame-render", this.showLoading.bind(this))

    // タブクリック時のイベントリスナーを追加
    this.tabTargets.forEach(tab => {
      tab.addEventListener('click', this.switchTab.bind(this))
    })
  }

  disconnect() {
    this.contentTarget.removeEventListener("turbo:frame-load", this.hideLoading.bind(this))
    this.contentTarget.removeEventListener("turbo:before-frame-render", this.showLoading.bind(this))
  }

  switchTab(event) {
    // クリックされたタブを取得
    const clickedTab = event.currentTarget

    // 全タブのアクティブ状態をリセット
    this.tabTargets.forEach(tab => {
      tab.classList.remove('border-blue-500', 'text-blue-600', 'dark:text-blue-400')
      tab.classList.add('border-transparent', 'text-gray-500', 'hover:text-gray-700', 'hover:border-gray-300', 'dark:text-gray-400', 'dark:hover:text-gray-300', 'dark:hover:border-gray-600')
    })

    // クリックされたタブをアクティブに
    clickedTab.classList.remove('border-transparent', 'text-gray-500', 'hover:text-gray-700', 'hover:border-gray-300', 'dark:text-gray-400', 'dark:hover:text-gray-300', 'dark:hover:border-gray-600')
    clickedTab.classList.add('border-blue-500', 'text-blue-600', 'dark:text-blue-400')
  }

  showLoading() {
    // ローディング表示
    const loadingHTML = `
      <div class="flex items-center justify-center py-12">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
        <span class="ml-3 text-gray-600 dark:text-gray-400">読み込み中...</span>
      </div>
    `
    // 既存のコンテンツの前にローディング表示を追加
    if (!this.contentTarget.querySelector('.loading-indicator')) {
      const loadingDiv = document.createElement('div')
      loadingDiv.className = 'loading-indicator'
      loadingDiv.innerHTML = loadingHTML
      this.contentTarget.insertBefore(loadingDiv, this.contentTarget.firstChild)
    }
  }

  hideLoading() {
    // ローディング表示を削除
    const loadingIndicator = this.contentTarget.querySelector('.loading-indicator')
    if (loadingIndicator) {
      loadingIndicator.remove()
    }
  }
}
