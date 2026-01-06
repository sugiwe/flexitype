import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown"]

  connect() {
    // ドロップダウン外クリックで閉じる
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
  }

  disconnect() {
    document.removeEventListener('click', this.closeOnOutsideClick)
  }

  // ドロップダウンの開閉トグル
  toggle(event) {
    event.stopPropagation()
    const isOpen = !this.dropdownTarget.classList.contains('hidden')

    if (isOpen) {
      this.closeDropdown()
    } else {
      this.openDropdown()
    }
  }

  openDropdown() {
    this.dropdownTarget.classList.remove('hidden')
    document.addEventListener('click', this.closeOnOutsideClick)
  }

  closeDropdown() {
    this.dropdownTarget.classList.add('hidden')
    document.removeEventListener('click', this.closeOnOutsideClick)
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.closeDropdown()
    }
  }

  // 言語選択
  select(event) {
    const localeId = event.currentTarget.dataset.localeId
    // URLに?locale=enのようなパラメータを付けてリロード（Cookieに保存される）
    const url = new URL(window.location.href)
    url.searchParams.set('locale', localeId)
    window.location.href = url.toString()
  }
}
