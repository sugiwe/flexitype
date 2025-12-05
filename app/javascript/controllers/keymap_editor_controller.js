import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["currentLayer", "inputArea", "selectedKeyLabel", "charInput", "keyChar", "saveStatus"]
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

    // レイヤーボタンの見た目を更新
    const buttons = event.currentTarget.parentElement.querySelectorAll("button")
    buttons.forEach(btn => {
      if (parseInt(btn.dataset.layer) === layer) {
        btn.className = "px-4 py-2 rounded bg-blue-600 text-white"
      } else {
        btn.className = "px-4 py-2 rounded bg-white text-gray-700 hover:bg-gray-200"
      }
    })

    // 現在のレイヤー表示を更新
    this.currentLayerTarget.textContent = `Layer ${layer}`

    // キーボード表示を更新
    this.updateKeyboardDisplay()

    // 入力エリアを非表示
    this.hideInputArea()
  }

  // キーを選択
  selectKey(event) {
    this.selectedKey = event.currentTarget.dataset.position
    this.selectedKeyElement = event.currentTarget

    // 選択したキーの情報を表示
    this.selectedKeyLabelTarget.textContent = this.selectedKey

    // 既存の値があれば入力欄に表示
    const currentChar = this.keymaps[this.currentLayer][this.selectedKey] || ""
    this.charInputTarget.value = currentChar

    // 入力エリアを表示
    this.showInputArea()

    // 入力欄にフォーカス
    this.charInputTarget.focus()
  }

  // 文字を更新（リアルタイム）
  updateChar(event) {
    // 特に何もしない（saveCharで保存）
  }

  // 文字を設定
  saveChar() {
    const char = this.charInputTarget.value.trim()

    if (char === "") {
      alert("文字を入力してください")
      return
    }

    // キーマップデータに保存
    this.keymaps[this.currentLayer][this.selectedKey] = char

    // キーボード表示を更新
    this.updateKeyCharacter(this.selectedKeyElement, char)

    // 入力エリアを非表示
    this.hideInputArea()

    console.log("Saved:", "Layer", this.currentLayer, this.selectedKey, "=", char)
  }

  // 編集をキャンセル
  cancelEdit() {
    this.hideInputArea()
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

  // 入力エリアを表示
  showInputArea() {
    this.inputAreaTarget.style.display = "block"
  }

  // 入力エリアを非表示
  hideInputArea() {
    this.inputAreaTarget.style.display = "none"
    this.selectedKey = null
    this.selectedKeyElement = null
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
}
