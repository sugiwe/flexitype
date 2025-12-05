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

  connect() {
    console.log("Typing controller connected")
    this.currentWordValue = 0
    this.currentPosition = 0
    this.hasError = false // ミスタイプのフラグ
    this.updateDisplay()
    this.highlightNextKey()
  }

  // 入力イベント
  handleInput(event) {
    const input = event.target.value
    const currentWord = this.words[this.currentWordValue]
    const previousLength = this.currentPosition

    // BackSpaceが押された場合（入力が減った場合）
    if (input.length < previousLength) {
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
      // 間違った入力
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

  // 次に打つべきキーをハイライト
  highlightNextKey() {
    // 以前のハイライトを全て解除
    document.querySelectorAll('.key').forEach(key => {
      key.classList.remove('ring-4', 'ring-yellow-400', 'bg-yellow-100')
    })

    // 次に打つべき文字を取得
    const currentWord = this.words[this.currentWordValue]
    const nextChar = currentWord[this.currentPosition]

    if (!nextChar) return // 単語の終わりに達した場合

    // 対応するキーを探してハイライト
    const keyLabel = this.keyMapping[nextChar.toLowerCase()]
    if (keyLabel) {
      // キーのテキストが一致する要素を探す
      document.querySelectorAll('.key').forEach(key => {
        if (key.textContent.trim() === keyLabel) {
          key.classList.add('ring-4', 'ring-yellow-400', 'bg-yellow-100')
        }
      })
    }
  }

  // ヘルパー: 単語リスト取得
  get words() {
    return this.wordsValue
  }
}
