import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "display", "progress", "currentIndex"]
  static values = {
    words: Array,
    currentWord: Number,
    keymaps: Object
  }

  // キーマップから動的に生成する（初期化時に設定）
  keyMapping = {}

  // 指ごとのキー位置マッピング（data-position）
  fingerPositionMapping = {
    // 左手
    'left-pinky': ['L0-R0', 'L0-R1', 'L1-R0', 'L1-R1', 'L2-R0', 'L2-R1', 'L3-R0', 'L3-R1'],
    'left-ring': ['L0-R2', 'L1-R2', 'L2-R2', 'L3-R2'],
    'left-middle': ['L0-R3', 'L1-R3', 'L2-R3'],
    'left-index': ['L0-R4', 'L0-R5', 'L1-R4', 'L1-R5', 'L2-R4', 'L2-R5'],
    'left-thumb': ['L3-R3', 'L3-R4', 'L3-R5'],
    // 右手
    'right-thumb': ['R3-R0', 'R3-R1', 'R3-R2'],
    'right-index': ['R0-R0', 'R0-R1', 'R1-R0', 'R1-R1', 'R2-R0', 'R2-R1'],
    'right-middle': ['R0-R2', 'R1-R2', 'R2-R2'],
    'right-ring': ['R0-R3', 'R1-R3', 'R2-R3', 'R3-R3'],
    'right-pinky': ['R0-R4', 'R0-R5', 'R1-R4', 'R1-R5', 'R2-R4', 'R2-R5', 'R3-R4', 'R3-R5']
  }

  // 指ごとの色（薄い背景色と濃いハイライト色）
  fingerColors = {
    'left-pinky': { light: 'bg-red-100', dark: 'bg-red-300' },
    'left-ring': { light: 'bg-yellow-100', dark: 'bg-yellow-300' },
    'left-middle': { light: 'bg-blue-100', dark: 'bg-blue-300' },
    'left-index': { light: 'bg-green-100', dark: 'bg-green-300' },
    'left-thumb': { light: 'bg-gray-100', dark: 'bg-gray-300' },
    'right-thumb': { light: 'bg-gray-100', dark: 'bg-gray-300' },
    'right-index': { light: 'bg-green-100', dark: 'bg-green-300' },
    'right-middle': { light: 'bg-blue-100', dark: 'bg-blue-300' },
    'right-ring': { light: 'bg-yellow-100', dark: 'bg-yellow-300' },
    'right-pinky': { light: 'bg-red-100', dark: 'bg-red-300' }
  }

  connect() {
    console.log("Typing controller connected")
    this.currentWordValue = 0
    this.currentPosition = 0
    this.hasError = false // ミスタイプのフラグ
    this.currentLayer = 0 // 現在のレイヤー

    // キーマップから逆引きマップを生成
    this.buildKeyMapping()

    this.applyFingerColors() // 指ごとの色を適用
    this.updateDisplay()
    this.highlightNextKey()
  }

  // キーマップから文字→キー位置の逆引きマップを生成
  buildKeyMapping() {
    console.log("Keymaps received:", this.keymapsValue)
    const layer0 = this.keymapsValue[0] || this.keymapsValue["0"] || {}
    console.log("Layer 0 data:", layer0)

    // 文字 → キー位置のマッピングを作成
    Object.entries(layer0).forEach(([position, char]) => {
      // "Q/q" のような形式の場合、スラッシュで分割して小文字側を取得
      let targetChar = char
      if (char.includes('/')) {
        const parts = char.split('/')
        // 後半（小文字側）を取得
        targetChar = parts[1] || parts[0]
      }

      // 小文字のアルファベットのみマッピング（特殊キーは除く）
      const normalized = targetChar.toLowerCase()
      if (normalized.match(/^[a-z]$/)) {
        this.keyMapping[normalized] = position
      }
    })

    console.log("Key mapping built:", this.keyMapping)
  }

  // 入力イベント
  handleInput(event) {
    const input = event.target.value
    const currentWord = this.words[this.currentWordValue]
    const previousLength = this.currentPosition

    // エラー状態で、かつBackSpaceではない入力の場合は無視（入力ロック）
    if (this.hasError && input.length >= previousLength + 1) {
      // 入力を元に戻す（ミスした文字の次の文字が入力されないようにする）
      event.target.value = input.slice(0, previousLength + 1)
      return
    }

    // BackSpaceが押された場合（入力が減った場合）
    if (input.length < previousLength || (this.hasError && input.length < previousLength + 1)) {
      this.currentPosition = input.length
      this.hasError = false // エラー状態を解除
      this.updateDisplay()
      this.highlightNextKey()
      return
    }

    // 新しい文字が入力された場合
    const expectedChar = currentWord[this.currentPosition]
    const typedChar = input[input.length - 1]

    if (typedChar === expectedChar) {
      // 正しい入力
      this.currentPosition = input.length
      this.hasError = false
      this.updateDisplay()
      this.highlightNextKey()

      // 単語を完全に入力したら次の単語へ
      if (input === currentWord) {
        setTimeout(() => this.nextWord(), 300) // 少し間を置いてから次へ
      }
    } else {
      // 間違った入力（入力をロック）
      this.hasError = true
      this.updateDisplay()
    }
  }

  // 次の単語へ進む
  nextWord() {
    this.currentWordValue += 1
    this.currentPosition = 0
    this.inputTarget.value = ""
    this.hasError = false

    if (this.currentWordValue >= this.words.length) {
      // 全単語完了
      alert("お疲れ様でした！全ての単語を入力しました！")
      this.currentWordValue = 0
    }

    this.updateDisplay()
    this.highlightNextKey()
  }

  // 表示を更新
  updateDisplay() {
    const currentWord = this.words[this.currentWordValue]
    const completed = currentWord.slice(0, this.currentPosition)
    const current = currentWord[this.currentPosition] || ""
    const remaining = currentWord.slice(this.currentPosition + 1)

    // 単語表示を更新
    if (this.hasError) {
      // ミスタイプ時: 現在の文字を赤く表示
      this.displayTarget.innerHTML = `
        <span class="text-green-600 font-semibold">${completed}</span><span class="text-red-600 border-b-4 border-red-600 font-semibold">${current}</span><span class="text-gray-400">${remaining}</span>
      `
    } else {
      // 通常時: 現在の文字を青く表示
      this.displayTarget.innerHTML = `
        <span class="text-green-600 font-semibold">${completed}</span><span class="text-blue-600 border-b-4 border-blue-600 font-semibold">${current}</span><span class="text-gray-400">${remaining}</span>
      `
    }

    // 進捗表示を更新
    this.progressTarget.textContent = `問題 ${this.currentWordValue + 1} / ${this.words.length}`
  }

  // キーボードに指ごとの色を適用
  applyFingerColors() {
    Object.entries(this.fingerPositionMapping).forEach(([finger, positions]) => {
      const colors = this.fingerColors[finger]
      positions.forEach(position => {
        const keyElement = document.querySelector(`.key[data-position="${position}"]`)
        if (keyElement) {
          // bg-whiteを削除して、指ごとの色（薄い色）を追加
          keyElement.classList.remove('bg-white')
          keyElement.classList.add(colors.light)
          // data属性に指情報を保存
          keyElement.dataset.finger = finger
        }
      })
    })
  }

  // 次に打つべきキーをハイライト
  highlightNextKey() {
    // 以前のハイライトを全て解除（全てのキーを薄い色に戻す）
    document.querySelectorAll('.key[data-finger]').forEach(key => {
      const finger = key.dataset.finger
      const colors = this.fingerColors[finger]
      if (colors) {
        // 濃い色を削除して薄い色に戻す
        key.classList.remove(colors.dark)
        if (!key.classList.contains(colors.light)) {
          key.classList.add(colors.light)
        }
        // リングも削除
        key.classList.remove('ring-4', 'ring-offset-2')
      }
    })

    // 指ガイドのハイライトも解除（濃い色だけ削除、薄い色は維持）
    document.querySelectorAll('.finger-guide').forEach(guide => {
      const finger = guide.dataset.finger
      const colors = this.fingerColors[finger]
      if (colors) {
        // 濃い色を削除
        guide.classList.remove(colors.dark)
        // 薄い色を追加（もし削除されていた場合のために）
        if (!guide.classList.contains(colors.light)) {
          guide.classList.add(colors.light)
        }
        // リングを削除
        guide.classList.remove('ring-4', 'ring-offset-2')
      }
    })

    // 次に打つべき文字を取得
    const currentWord = this.words[this.currentWordValue]
    const nextChar = currentWord[this.currentPosition]

    if (!nextChar) return // 単語の終わりに達した場合

    // キーマップから対応するキー位置を取得
    const keyPosition = this.keyMapping[nextChar.toLowerCase()]
    if (keyPosition) {
      // data-position属性でキーを検索
      const keyElement = document.querySelector(`.key[data-position="${keyPosition}"]`)
      if (keyElement) {
        const targetFinger = keyElement.dataset.finger
        if (targetFinger) {
          const colors = this.fingerColors[targetFinger]

          // キーを濃い色にする
          keyElement.classList.remove(colors.light)
          keyElement.classList.add(colors.dark)
          keyElement.classList.add('ring-4', 'ring-offset-2')

          // 指ガイドも濃い色にする
          const guideElement = document.querySelector(`.finger-guide[data-finger="${targetFinger}"]`)
          if (guideElement) {
            guideElement.classList.remove(colors.light)
            guideElement.classList.add(colors.dark)
            guideElement.classList.add('ring-4', 'ring-offset-2')
          }
        }
      }
    }
  }

  // ヘルパー: 単語リスト取得
  get words() {
    return this.wordsValue
  }
}
