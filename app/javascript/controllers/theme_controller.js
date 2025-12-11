import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "currentIcon", "currentName"]
  static values = {
    current: { type: String, default: "system" }
  }

  // テーマ定義（SVGアイコン用）
  themes = [
    {
      id: 'light',
      name: 'Light',
      icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"></path></svg>'
    },
    {
      id: 'dark',
      name: 'Dark',
      icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"></path></svg>'
    },
    {
      id: 'system',
      name: 'System',
      icon: '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path></svg>'
    }
    // 将来の拡張用:
    // { id: 'github', name: 'GitHub', icon: '<svg>...</svg>' }
  ]

  connect() {
    // ページ読み込み完了を待ってから実行
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => this.initialize())
    } else {
      this.initialize()
    }

    // ドロップダウン外クリックで閉じる
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
  }

  initialize() {
    // LocalStorageから設定を読み込み
    const savedTheme = localStorage.getItem('theme') || 'system'
    this.currentValue = savedTheme
    this.applyTheme(savedTheme)
    this.updateCurrentThemeDisplay()

    // System設定の場合、OSの設定変更を監視
    if (savedTheme === 'system') {
      this.watchSystemTheme()
    }
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

  // テーマ選択
  select(event) {
    const themeId = event.currentTarget.dataset.themeId
    this.currentValue = themeId
    localStorage.setItem('theme', themeId)
    this.applyTheme(themeId)
    this.updateCurrentThemeDisplay()
    this.closeDropdown()

    // System設定の場合、OSの設定変更を監視
    if (themeId === 'system') {
      this.watchSystemTheme()
    }
  }

  // 現在のテーマ表示を更新
  updateCurrentThemeDisplay() {
    const theme = this.currentTheme
    if (this.hasCurrentIconTarget) {
      this.currentIconTarget.innerHTML = theme.icon
    }
    if (this.hasCurrentNameTarget) {
      this.currentNameTarget.textContent = theme.name
    }
  }

  // テーマを適用
  applyTheme(themeId) {
    const html = document.documentElement

    if (themeId === 'system') {
      // OSの設定に従う
      const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
      html.classList.toggle('dark', systemPrefersDark)
    } else if (themeId === 'dark') {
      html.classList.add('dark')
    } else if (themeId === 'light') {
      html.classList.remove('dark')
    }
    // 将来のカスタムテーマ用:
    // else if (themeId === 'github') {
    //   html.classList.add('theme-github')
    // }
  }

  // OSのテーマ設定変更を監視
  watchSystemTheme() {
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    const handler = (e) => {
      if (this.currentValue === 'system') {
        document.documentElement.classList.toggle('dark', e.matches)
      }
    }

    // 既存のリスナーを削除してから新しいものを追加
    mediaQuery.removeEventListener('change', handler)
    mediaQuery.addEventListener('change', handler)
  }

  // 現在のテーマ情報を取得
  get currentTheme() {
    return this.themes.find(t => t.id === this.currentValue) || this.themes[2] // デフォルトはsystem
  }
}
