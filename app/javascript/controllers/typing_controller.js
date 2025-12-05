import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "display", "progress", "currentIndex"]
  static values = {
    words: Array,
    currentWord: Number
  }

  connect() {
    console.log("Typing controller connected")
    this.currentWordValue = 0
    this.currentPosition = 0
    this.updateDisplay()
  }

  // 入力イベント
  handleInput(event) {
    const input = event.target.value
    const currentWord = this.words[this.currentWordValue]

    // 入力値が正解の単語の先頭と一致するかチェック
    if (currentWord.startsWith(input)) {
      this.currentPosition = input.length
      this.updateDisplay()

      // 単語を完全に入力したら次の単語へ
      if (input === currentWord) {
        this.nextWord()
      }
    } else {
      // 間違った入力の場合は入力を戻す
      event.target.value = input.slice(0, -1)
    }
  }

  // BackSpace対応（handleInputで自動的に処理される）

  // 次の単語へ進む
  nextWord() {
    this.currentWordValue += 1
    this.currentPosition = 0
    this.inputTarget.value = ""

    if (this.currentWordValue >= this.words.length) {
      // 全単語完了
      alert("お疲れ様でした！全ての単語を入力しました！")
      this.currentWordValue = 0
    }

    this.updateDisplay()
  }

  // 表示を更新
  updateDisplay() {
    const currentWord = this.words[this.currentWordValue]
    const completed = currentWord.slice(0, this.currentPosition)
    const current = currentWord[this.currentPosition] || ""
    const remaining = currentWord.slice(this.currentPosition + 1)

    // 単語表示を更新
    this.displayTarget.innerHTML = `
      <span class="text-green-600 font-semibold">${completed}</span><span class="text-blue-600 border-b-4 border-blue-600 font-semibold">${current}</span><span class="text-gray-400">${remaining}</span>
    `

    // 進捗表示を更新
    this.progressTarget.textContent = `問題 ${this.currentWordValue + 1} / ${this.words.length}`
  }

  // ヘルパー: 単語リスト取得
  get words() {
    return this.wordsValue
  }
}
