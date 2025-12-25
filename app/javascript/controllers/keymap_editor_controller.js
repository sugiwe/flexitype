import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectedDisplay", "candidateGroup", "keyChar", "saveStatus"]
  static values = { existingKeymaps: Object, keymapSetSlug: String }

  connect() {
    console.log("Keymap editor controller connected")

    // 既存のキーマップデータを読み込む
    if (this.hasExistingKeymapsValue && Object.keys(this.existingKeymapsValue).length > 0) {
      this.keymaps = this.existingKeymapsValue
      console.log("Loaded existing keymaps:", this.keymaps)
    } else {
      // キーマップデータを初期化（6レイヤー分）
      this.keymaps = {}
      for (let i = 0; i < 6; i++) {
        this.keymaps[i] = {}
      }
    }

    this.currentLayer = 0
    this.selectedKey = null
    this.selectedKeyElement = null

    // 初期表示を更新
    this.updateKeyboardDisplay()
  }

  // レイヤー切り替え
  switchLayer(event) {
    const layer = parseInt(event.currentTarget.dataset.layer)
    this.currentLayer = layer

    // レイヤーボタンの見た目を更新（ダークモード対応）
    const buttons = event.currentTarget.parentElement.querySelectorAll("button")
    buttons.forEach(btn => {
      if (parseInt(btn.dataset.layer) === layer) {
        btn.className = "px-4 py-2 rounded transition bg-blue-600 dark:bg-blue-700 text-white"
      } else {
        btn.className = "px-4 py-2 rounded transition bg-white dark:bg-gray-600 text-gray-700 dark:text-gray-200 hover:bg-gray-200 dark:hover:bg-gray-500"
      }
    })

    // キーボード表示を更新
    this.updateKeyboardDisplay()

    // 選択状態をリセット
    if (this.selectedKeyElement) {
      this.selectedKeyElement.classList.remove('ring-4', 'ring-green-500', 'ring-offset-2')
    }
    this.selectedKey = null
    this.selectedKeyElement = null
  }

  // キーを選択（登録待ち状態にする）
  selectKey(event) {
    // 前回選択したキーのハイライトを解除
    if (this.selectedKeyElement) {
      this.selectedKeyElement.classList.remove('ring-4', 'ring-green-500', 'ring-offset-2')
    }

    // 新しく選択したキーをハイライト
    this.selectedKey = event.currentTarget.dataset.position
    this.selectedKeyElement = event.currentTarget
    this.selectedKeyElement.classList.add('ring-4', 'ring-green-500', 'ring-offset-2')
  }

  // 文字を割り当て
  assignChar(event) {
    if (!this.selectedKey) {
      alert('先にキーを選択してください')
      return
    }

    const char = event.currentTarget.dataset.char

    // キーマップデータに保存
    this.keymaps[this.currentLayer][this.selectedKey] = char

    // キーボード表示を更新
    this.updateKeyCharacter(this.selectedKeyElement, char)

    // 選択状態を解除
    this.selectedKeyElement.classList.remove('ring-4', 'ring-green-500', 'ring-offset-2')
    this.selectedKey = null
    this.selectedKeyElement = null

    console.log("Assigned:", "Layer", this.currentLayer, "=", char)
  }

  // キーボード全体の表示を更新
  updateKeyboardDisplay() {
    const layerData = this.keymaps[this.currentLayer]

    this.keyCharTargets.forEach(target => {
      const keyElement = target.closest(".key")
      const position = keyElement.dataset.position
      const char = layerData[position] || ""
      target.innerHTML = this.formatKeyDisplay(char)

      // blankの場合は親要素に背景を設定
      if (char && char.toLowerCase() === 'blank') {
        keyElement.classList.add('bg-gray-600', 'dark:bg-gray-800')
        keyElement.classList.remove('bg-white', 'dark:bg-gray-700')
      } else {
        keyElement.classList.remove('bg-gray-600', 'dark:bg-gray-800')
        keyElement.classList.add('bg-white', 'dark:bg-gray-700')
      }
    })
  }

  // 特定のキーの文字を更新
  updateKeyCharacter(keyElement, char) {
    const charTarget = keyElement.querySelector("[data-keymap-editor-target='keyChar']")
    if (charTarget) {
      charTarget.innerHTML = this.formatKeyDisplay(char)

      // blankの場合は親要素に背景を設定
      if (char && char.toLowerCase() === 'blank') {
        keyElement.classList.add('bg-gray-600', 'dark:bg-gray-800')
        keyElement.classList.remove('bg-white', 'dark:bg-gray-700')
      } else {
        keyElement.classList.remove('bg-gray-600', 'dark:bg-gray-800')
        keyElement.classList.add('bg-white', 'dark:bg-gray-700')
      }
    }
  }

  // format_key_displayヘルパーのJavaScript版（2段表示対応）
  formatKeyDisplay(char) {
    if (!char) return '<div class="text-xs"></div>'

    // blankの場合は✕マーク（背景は親要素で設定）
    if (char.toLowerCase() === 'blank') {
      return '<div class="text-base text-gray-300 dark:text-gray-400">✕</div>'
    }

    // 特殊キーの表示名マッピング（1段表示）
    const specialKeys = {
      'spc': 'Spc', 'space': 'Spc',
      'bs': 'BS', 'backspace': 'BS',
      'ent': 'Ent', 'enter': 'Ent',
      'tab': 'Tab',
      'esc': 'Esc',
      'del': 'Del',
      'layer1': 'Lyr1', 'lyr1': 'Lyr1',
      'layer2': 'Lyr2', 'lyr2': 'Lyr2',
      'layer3': 'Lyr3', 'lyr3': 'Lyr3',
      'layer4': 'Lyr4', 'lyr4': 'Lyr4',
      'layer5': 'Lyr5', 'lyr5': 'Lyr5',
      'lower': 'Lower',
      'raise': 'Raise',
      'shift': 'Shift',
      'ctrl': 'Ctrl',
      'alt': 'Alt',
      'cmd': 'Cmd',
      'caps': 'Caps',
      'fn': 'Fn',
      'f1': 'F1', 'f2': 'F2', 'f3': 'F3', 'f4': 'F4',
      'f5': 'F5', 'f6': 'F6', 'f7': 'F7', 'f8': 'F8',
      'f9': 'F9', 'f10': 'F10', 'f11': 'F11', 'f12': 'F12'
    }

    const lowerChar = char.toLowerCase()
    if (specialKeys[lowerChar]) {
      return `<div class="text-xs text-gray-700 dark:text-gray-200">${specialKeys[lowerChar]}</div>`
    }

    // "Q|q" や "!|1" 形式の場合は2段表示
    // 上段: 小さめ・グレー、下段: 大きめ・太字・黒
    if (char.includes('|')) {
      const parts = char.split('|')
      const upper = parts[0] || ''
      const lower = parts[1] || ''

      return `
        <div class="flex flex-col items-center justify-center h-full">
          <div class="text-xs text-gray-400 dark:text-gray-400 mb-1">${upper}</div>
          <div class="text-base font-semibold text-gray-700 dark:text-gray-200">${lower}</div>
        </div>
      `
    }

    // 単一文字の場合
    return `<div class="text-xs text-gray-700 dark:text-gray-200">${char}</div>`
  }

  // タブ切り替え
  switchTab(event) {
    const targetTab = event.currentTarget.dataset.tab

    // タブボタンの見た目を更新（ダークモード対応）
    const buttons = event.currentTarget.parentElement.querySelectorAll("button")
    buttons.forEach(btn => {
      if (btn.dataset.tab === targetTab) {
        btn.className = "px-6 py-2 rounded transition bg-blue-600 dark:bg-blue-700 text-white"
      } else {
        btn.className = "px-6 py-2 rounded transition bg-white dark:bg-gray-600 text-gray-700 dark:text-gray-200 hover:bg-gray-200 dark:hover:bg-gray-500"
      }
    })

    // 候補グループの表示切り替え
    this.candidateGroupTargets.forEach(group => {
      if (group.dataset.category === targetTab) {
        group.style.display = "block"
      } else {
        group.style.display = "none"
      }
    })
  }

  // キーマップを保存
  async saveKeymap() {
    console.log("Saving keymap...", this.keymaps)

    try {
      const csrfToken = document.querySelector("[name='csrf-token']").content
      const keymapSetSlug = this.keymapSetSlugValue

      // 基本情報フォームから名前と説明を取得
      const form = document.getElementById("basic-info-form")
      const name = form.querySelector("[name='keymap_set[name]']").value
      const description = form.querySelector("[name='keymap_set[description]']").value
      const slug = form.querySelector("[name='keymap_set[slug]']").value

      const response = await fetch(`/my/keymaps/${keymapSetSlug}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({
          keymap_set: {
            name: name,
            description: description,
            slug: slug
          },
          keymaps: this.keymaps
        })
      })

      if (response.ok) {
        const data = await response.json()
        console.log("Save successful:", data)

        // 保存成功メッセージを表示（データから取得）
        this.saveStatusTarget.textContent = `✓ ${data.message}`
        this.saveStatusTarget.style.display = "block"
        setTimeout(() => {
          this.saveStatusTarget.style.display = "none"
        }, 3000)
      } else {
        const errorData = await response.json()
        const errorMessage = errorData.error || "不明なエラー"
        alert("保存に失敗しました: " + errorMessage)
      }
    } catch (error) {
      console.error("Save error:", error)
      alert("保存中にエラーが発生しました")
    }
  }

  // デフォルトに戻す
  async resetToDefault() {
    // 確認ダイアログを表示
    const confirmed = confirm("現在のキーマップをデフォルト設定に戻しますか？\nこの操作は取り消せません。")

    if (!confirmed) {
      return
    }

    try {
      const csrfToken = document.querySelector("[name='csrf-token']").content
      const keymapSetSlug = this.keymapSetSlugValue
      const response = await fetch(`/my/keymaps/${keymapSetSlug}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({
          reset_to_default: true
        })
      })

      if (response.ok) {
        // リセット成功したらページをリロードしてデフォルト状態を表示
        window.location.reload()
      } else {
        const errorData = await response.json()
        const errorMessage = errorData.error || "デフォルト設定に戻すことができませんでした"
        alert(errorMessage)
      }
    } catch (error) {
      console.error("Reset error:", error)
      alert("デフォルト設定に戻す際にエラーが発生しました")
    }
  }
}
