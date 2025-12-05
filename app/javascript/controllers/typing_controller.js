import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "display", "progress", "currentIndex"]
  static values = {
    words: Array,
    currentWord: Number
  }

  // キーと文字のマッピング（Layer 0のみ、小文字）
  keyMapping = {
    'q': 'Q', 'w': 'W', 'e': 'E', 'r': 'R', 't': 'T',
    'y': 'Y', 'u': 'U', 'i': 'I', 'o': 'O', 'p': 'P',
    'a': 'A', 's': 'S', 'd': 'D', 'f': 'F', 'g': 'G',
    'h': 'H', 'j': 'J', 'k': 'K', 'l': 'L',
    'z': 'Z', 'x': 'X', 'c': 'C', 'v': 'V', 'b': 'B',
    'n': 'N', 'm': 'M'
  }

  // 指ごとのキーマッピング
  fingerMapping = {
    // 左手
    'left-pinky': ['Q', 'A', 'Z', 'Tab', 'Caps', 'Shift'],
    'left-ring': ['W', 'S', 'X'],
    'left-middle': ['E', 'D', 'C'],
    'left-index': ['R', 'F', 'V', 'T', 'G', 'B'],
    // 右手
    'right-index': ['Y', 'H', 'N', 'U', 'J', 'M'],
    'right-middle': ['I', 'K', ','],
    'right-ring': ['O', 'L', '.'],
    'right-pinky': ['P', '-', 'Up', 'BS', 'Ent', '/']
  }

  // 指ごとの色（薄い背景色と濃いハイライト色）
  fingerColors = {
    'left-pinky': { light: 'bg-red-100', dark: 'bg-red-300' },
    'left-ring': { light: 'bg-yellow-100', dark: 'bg-yellow-300' },
    'left-middle': { light: 'bg-blue-100', dark: 'bg-blue-300' },
    'left-index': { light: 'bg-green-100', dark: 'bg-green-300' },
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
    this.applyFingerColors() // 指ごとの色を適用
    this.updateDisplay()
    this.highlightNextKey()
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
    Object.entries(this.fingerMapping).forEach(([finger, keys]) => {
      const colors = this.fingerColors[finger]
      keys.forEach(keyLabel => {
        document.querySelectorAll('.key').forEach(key => {
          if (key.textContent.trim() === keyLabel) {
            // bg-whiteを削除して、指ごとの色（薄い色）を追加
            key.classList.remove('bg-white')
            key.classList.add(colors.light)
            // data属性に指情報を保存
            key.dataset.finger = finger
          }
        })
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

    // 指ガイドのハイライトも解除
    document.querySelectorAll('.finger-guide').forEach(guide => {
      const finger = guide.dataset.finger
      const colors = this.fingerColors[finger]
      if (colors) {
        guide.classList.remove(colors.dark)
        guide.classList.remove('ring-4', 'ring-offset-2')
      }
    })

    // 次に打つべき文字を取得
    const currentWord = this.words[this.currentWordValue]
    const nextChar = currentWord[this.currentPosition]

    if (!nextChar) return // 単語の終わりに達した場合

    // 対応するキーを探してハイライト
    const keyLabel = this.keyMapping[nextChar.toLowerCase()]
    if (keyLabel) {
      // 対応する指を見つける
      let targetFinger = null
      Object.entries(this.fingerMapping).forEach(([finger, keys]) => {
        if (keys.includes(keyLabel)) {
          targetFinger = finger
        }
      })

      if (targetFinger) {
        const colors = this.fingerColors[targetFinger]

        // キーを濃い色にする
        document.querySelectorAll('.key').forEach(key => {
          if (key.textContent.trim() === keyLabel) {
            key.classList.remove(colors.light)
            key.classList.add(colors.dark)
            key.classList.add('ring-4', 'ring-offset-2')
          }
        })

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

  // ヘルパー: 単語リスト取得
  get words() {
    return this.wordsValue
  }
}
