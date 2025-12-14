import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectedDisplay", "candidateGroup", "keyChar", "saveStatus"]
  static values = { existingKeymaps: Object }

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
      const char = layerData[position] || "-"
      target.textContent = char
    })
  }

  // 特定のキーの文字を更新
  updateKeyCharacter(keyElement, char) {
    const charTarget = keyElement.querySelector("[data-keymap-editor-target='keyChar']")
    if (charTarget) {
      charTarget.textContent = char
    }
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
      const response = await fetch("/keymaps/current", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({
          keymaps: this.keymaps
        })
      })

      if (response.ok) {
        const data = await response.json()
        console.log("Save successful:", data)

        // 保存成功メッセージを表示
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
      // デフォルトキーマップを取得
      const response = await fetch("/keymaps/default")

      if (response.ok) {
        const defaultKeymaps = await response.json()
        console.log("Default keymaps loaded:", defaultKeymaps)

        // キーマップデータを置き換え
        this.keymaps = defaultKeymaps

        // 表示を更新
        this.updateKeyboardDisplay()

        alert("デフォルト設定に戻しました。「すべてのレイヤーを保存」ボタンを押して保存してください。")
      } else {
        alert("デフォルト設定の読み込みに失敗しました")
      }
    } catch (error) {
      console.error("Reset error:", error)
      alert("デフォルト設定の読み込み中にエラーが発生しました")
    }
  }
}
