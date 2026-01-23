import { Controller } from "@hotwired/stimulus"
import { convertToRomaji, getDefaultRomajiString, isJapaneseText } from "lib/romaji_converter"

export default class extends Controller {
  static targets = ["input", "display", "progress", "currentIndex", "completionScreen", "lessonScreen", "accuracyDisplay", "timeDisplay", "mistakesDisplay", "displayArea", "gradeImage", "gradeName", "gradeDescription", "wpmDisplay"]
  static values = {
    words: Array,
    currentWord: Number,
    keymaps: Object,
    lessonInfo: Object,
    loggedIn: Boolean,
    grades: Object,
    keyboardType: String
  }

  // キーマップから動的に生成する（初期化時に設定）
  keyMapping = {}

  // 指ごとのキー位置マッピング（キーボードタイプ別）
  fingerPositionMappings = {
    'split_4x6': {
      // 左手
      'left-pinky': ['0-0', '0-1', '1-0', '1-1', '2-0', '2-1', '3-0', '3-1'],
      'left-ring': ['0-2', '1-2', '2-2', '3-2'],
      'left-middle': ['0-3', '1-3', '2-3'],
      'left-index': ['0-4', '0-5', '1-4', '1-5', '2-4', '2-5'],
      'left-thumb': ['3-3', '3-4', '3-5'],
      // 右手
      'right-thumb': ['9-0', '9-1', '9-2'],
      'right-index': ['6-0', '6-1', '7-0', '7-1', '8-0', '8-1'],
      'right-middle': ['6-2', '7-2', '8-2'],
      'right-ring': ['6-3', '7-3', '8-3', '9-3'],
      'right-pinky': ['6-4', '6-5', '7-4', '7-5', '8-4', '8-5', '9-4', '9-5']
    },
    'ortho_4x12': {
      // 4×6分割型を横に並べた配列（左手: 列0-5、右手: 列6-11）
      // 左手
      'left-pinky': ['0-0', '0-1', '1-0', '1-1', '2-0', '2-1', '3-0', '3-1'],
      'left-ring': ['0-2', '1-2', '2-2', '3-2'],
      'left-middle': ['0-3', '1-3', '2-3'],
      'left-index': ['0-4', '0-5', '1-4', '1-5', '2-4', '2-5'],
      'left-thumb': ['3-3', '3-4', '3-5'],
      // 右手
      'right-thumb': ['3-6', '3-7', '3-8'],
      'right-index': ['0-6', '0-7', '1-6', '1-7', '2-6', '2-7'],
      'right-middle': ['0-8', '1-8', '2-8'],
      'right-ring': ['0-9', '1-9', '2-9', '3-9'],
      'right-pinky': ['0-10', '0-11', '1-10', '1-11', '2-10', '2-11', '3-10', '3-11']
    }
  }

  // 現在のキーボードタイプに応じた指マッピングを取得
  get fingerPositionMapping() {
    const keyboardType = this.keyboardTypeValue || 'split_4x6'
    return this.fingerPositionMappings[keyboardType] || this.fingerPositionMappings['split_4x6']
  }

  // 指ごとの色（薄い背景色と濃いハイライト色）
  // ライトモードとダークモード両方のクラスを含む
  fingerColors = {
    'left-pinky': { light: 'bg-red-100 dark:bg-red-900', dark: 'bg-red-300 dark:bg-red-700' },
    'left-ring': { light: 'bg-yellow-100 dark:bg-yellow-900', dark: 'bg-yellow-300 dark:bg-yellow-700' },
    'left-middle': { light: 'bg-blue-100 dark:bg-blue-900', dark: 'bg-blue-300 dark:bg-blue-700' },
    'left-index': { light: 'bg-green-100 dark:bg-green-900', dark: 'bg-green-300 dark:bg-green-700' },
    'left-thumb': { light: 'bg-gray-100 dark:bg-gray-800', dark: 'bg-gray-300 dark:bg-gray-600' },
    'right-thumb': { light: 'bg-gray-100 dark:bg-gray-800', dark: 'bg-gray-300 dark:bg-gray-600' },
    'right-index': { light: 'bg-green-100 dark:bg-green-900', dark: 'bg-green-300 dark:bg-green-700' },
    'right-middle': { light: 'bg-blue-100 dark:bg-blue-900', dark: 'bg-blue-300 dark:bg-blue-700' },
    'right-ring': { light: 'bg-yellow-100 dark:bg-yellow-900', dark: 'bg-yellow-300 dark:bg-yellow-700' },
    'right-pinky': { light: 'bg-red-100 dark:bg-red-900', dark: 'bg-red-300 dark:bg-red-700' }
  }

  connect() {
    this.currentWordValue = 0
    this.currentPosition = 0
    this.hasError = false // ミスタイプのフラグ
    this.currentLayer = 0 // 現在表示中のレイヤー

    // 統計情報
    this.mistakeCount = 0 // ミスタイプの総数
    this.totalKeystrokes = 0 // 総キー入力数
    this.typedChars = 0 // タイプした文字数（成績評価用）
    this.lessonStartTime = null // レッスン開始時刻（最初の入力時に設定）
    this.isFirstInput = true // 最初の入力かどうか

    // 日本語レッスンの判定とローマ字変換
    this.isJapaneseLesson = this.words.some(wordItem => {
      const text = typeof wordItem === 'string' ? wordItem : wordItem.text
      return isJapaneseText(text)
    })
    if (this.isJapaneseLesson) {
      this.prepareJapaneseLesson()
    }

    // キーマップから逆引きマップを生成（全レイヤー分）
    this.buildKeyMapping()

    this.applyFingerColors() // 指ごとの色を適用
    this.updateDisplay()
    this.highlightNextKey()

    // IMEを完全に無効化する設定
    this.inputTarget.style.imeMode = 'disabled' // 古いブラウザ用
    this.inputTarget.style.webkitImeMode = 'disabled' // Safari用
    this.inputTarget.setAttribute('autocorrect', 'off') // iOS用
    this.inputTarget.setAttribute('autocapitalize', 'off') // iOS用
    this.inputTarget.setAttribute('spellcheck', 'false') // スペルチェック無効

    // compositionイベントをキャンセル（IMEの変換候補を防ぐ）
    this.inputTarget.addEventListener('compositionstart', (event) => {
      event.preventDefault()
      event.stopPropagation()
      event.stopImmediatePropagation()
    })
    this.inputTarget.addEventListener('compositionupdate', (event) => {
      event.preventDefault()
      event.stopPropagation()
      event.stopImmediatePropagation()
    })
    this.inputTarget.addEventListener('compositionend', (event) => {
      event.preventDefault()
      event.stopPropagation()
      event.stopImmediatePropagation()
      // 入力フィールドをクリアして、IMEの変換結果を捨てる
      this.inputTarget.value = ''
    })

    // beforeinputイベントでIME入力を阻止（最も早い段階でブロック）
    this.inputTarget.addEventListener('beforeinput', (event) => {
      // IME関連のinputTypeを全てブロック
      if (event.inputType === 'insertCompositionText' ||
          event.inputType === 'deleteByComposition' ||
          event.inputType === 'deleteContentBackward' ||
          event.inputType === 'deleteContentForward') {
        // BackSpaceはkeydownで処理するのでここではブロック
        if (event.inputType.startsWith('delete')) {
          event.preventDefault()
          return
        }
        // IME入力はブロック
        event.preventDefault()
        event.stopPropagation()
        event.stopImmediatePropagation()
      }
    }, true) // キャプチャフェーズで実行

    // inputイベントもキャンセル（IMEの入力を完全に無視）
    this.inputTarget.addEventListener('input', (event) => {
      // IMEからの入力を即座にクリア
      if (event.inputType && event.inputType.startsWith('insert')) {
        const value = event.target.value
        // ASCII以外の文字が含まれている場合はクリア
        if (/[^\x00-\x7F]/.test(value)) {
          event.preventDefault()
          event.stopPropagation()
          event.stopImmediatePropagation()
          event.target.value = ''
        }
      }
    }, true) // キャプチャフェーズで実行

    // キーボード入力を直接拾う（IMEの影響を受けない）
    this.inputTarget.addEventListener('keydown', (event) => {
      this.handleKeydown(event)
    })

    // 入力欄に自動フォーカス
    this.inputTarget.focus()

    // フォーカス状態の監視
    this.inputTarget.addEventListener('focus', () => this.setActiveState(true))
    this.inputTarget.addEventListener('blur', () => this.setActiveState(false))

    // 初期状態をアクティブに設定
    this.setActiveState(true)

    // ページ離脱の警告を設定
    this.setupNavigationWarning()
  }

  disconnect() {
    // クリーンアップ: ページ離脱警告を解除
    this.removeNavigationWarning()
  }

  // 単語表示エリアクリック時に入力欄にフォーカス
  focusInput() {
    this.inputTarget.focus()
  }

  // アクティブ状態の設定
  setActiveState(isActive) {
    if (isActive) {
      // アクティブ時: 青い背景 + リング
      this.displayAreaTarget.classList.remove('bg-gray-100', 'dark:bg-gray-700')
      this.displayAreaTarget.classList.add('bg-blue-50', 'dark:bg-blue-900', 'ring-2', 'ring-blue-400', 'dark:ring-blue-500')
    } else {
      // 非アクティブ時: うっすらグレーの背景（ライトモード: gray-100, ダークモード: gray-700）
      this.displayAreaTarget.classList.remove('bg-blue-50', 'dark:bg-blue-900', 'ring-2', 'ring-blue-400', 'dark:ring-blue-500')
      this.displayAreaTarget.classList.add('bg-gray-100', 'dark:bg-gray-700')
    }
  }

  // キーマップから文字→キー位置の逆引きマップを生成（全レイヤー分）
  buildKeyMapping() {
    // 各レイヤーごとに文字 → {layer, position} のマッピングを作成
    // 例: 'a' => [{layer: 0, position: '2-0'}, {layer: 1, position: '1-3'}]
    this.keyMapping = {}

    // 全レイヤー（0-5）を走査
    for (let layer = 0; layer < 6; layer++) {
      const layerData = this.keymapsValue[layer] || this.keymapsValue[layer.toString()] || {}

      Object.entries(layerData).forEach(([position, char]) => {
        if (!char) return

        // "Q q" (半角スペース) のような形式の場合、分割
        let chars = []
        if (char.includes(' ')) {
          chars = char.split(' ')
        // 【後方互換性】"Q|q" (パイプ区切り) もサポート（既存データ用）
        // 単体の「|」文字との衝突を避けるため、2文字以上かつ「|」を含む場合のみ適用
        } else if (char.includes('|') && char.length > 1) {
          chars = char.split('|')
        } else {
          chars = [char]
        }

        // 各文字（大文字・小文字両方）をマッピング
        chars.forEach(targetChar => {
          if (!targetChar) return

          // アルファベット・数字・記号をマッピング
          const normalized = targetChar.toLowerCase()

          if (!this.keyMapping[normalized]) {
            this.keyMapping[normalized] = []
          }

          this.keyMapping[normalized].push({
            layer: layer,
            position: position,
            displayChar: char // 表示用の元の文字（"Q q"など）
          })
        })
      })
    }
  }

  // 日本語レッスンの準備（ローマ字変換データの生成）
  prepareJapaneseLesson() {
    // 各単語をローマ字に変換
    this.japaneseWords = this.words.map(wordItem => {
      // wordsが文字列配列かハッシュ配列かを判定
      const word = typeof wordItem === 'string' ? wordItem : wordItem.text
      const display = typeof wordItem === 'string' ? null : wordItem.display

      const romajiData = convertToRomaji(word)
      const defaultRomaji = getDefaultRomajiString(romajiData)

      return {
        original: word,        // 元のひらがな文字列（例: "しょうりした"）
        display: display,      // 表示用テキスト（例: "勝利した"）、nullの場合はoriginalを使用
        romajiData: romajiData, // ローマ字変換データ配列
        currentRomaji: defaultRomaji, // 現在のローマ字文字列（動的に変わる）
        romajiPosition: 0      // 現在のローマ字入力位置
      }
    })
  }

  // キーボード入力を直接処理（IMEの影響を受けない）
  handleKeydown(event) {
    // 修飾キー（Ctrl, Alt, Meta）が押されている場合はスキップ
    if (event.ctrlKey || event.altKey || event.metaKey) {
      return
    }

    const key = event.key

    // BackSpaceキーの処理
    if (key === 'Backspace') {
      event.preventDefault()
      this.handleBackspace()
      return
    }

    // 1文字の入力を受け付ける（英数字、記号、スペースなど）
    // 特殊キー（Enter, Tab, Escapeなど）は除外
    if (key.length === 1) {
      event.preventDefault() // IMEの動作を防ぐ
      this.handleCharInput(key.toLowerCase())
    }
  }

  // 文字入力の処理
  handleCharInput(char) {
    // 日本語レッスンの場合
    if (this.isJapaneseLesson) {
      this.handleJapaneseCharInput(char)
      return
    }

    // 英語レッスンの場合
    this.handleEnglishCharInput(char)
  }

  // BackSpaceの処理
  handleBackspace() {
    if (this.isJapaneseLesson) {
      const currentWordData = this.japaneseWords[this.currentWordValue]
      // エラー状態またはローマ字入力位置が0より大きい場合
      if (currentWordData.romajiPosition > 0 || this.hasError) {
        if (this.hasError) {
          // エラー状態の場合はエラーフラグのみクリア（位置は戻さない）
          this.hasError = false
        } else {
          // 正常状態の場合は位置を1つ戻す
          currentWordData.romajiPosition--
          this.rebuildRomajiPattern(currentWordData, this.getCurrentInput())
        }
        this.updateDisplay()
        this.highlightNextKey()
      }
    } else {
      if (this.currentPosition > 0 || this.hasError) {
        if (this.hasError) {
          this.hasError = false
        } else {
          this.currentPosition--
        }
        this.updateDisplay()
        this.highlightNextKey()
      }
    }
  }

  // 現在の入力文字列を取得
  getCurrentInput() {
    if (this.isJapaneseLesson) {
      const currentWordData = this.japaneseWords[this.currentWordValue]
      return currentWordData.currentRomaji.slice(0, currentWordData.romajiPosition)
    } else {
      const wordItem = this.words[this.currentWordValue]
      const currentWord = typeof wordItem === 'string' ? wordItem : wordItem.text
      return currentWord.slice(0, this.currentPosition)
    }
  }

  // 入力イベント（既存の互換性のため残す）
  handleInput(event) {
    // keydownで処理するため、このハンドラーは使わない
  }

  // 英語レッスンの文字入力処理
  handleEnglishCharInput(char) {
    const wordItem = this.words[this.currentWordValue]
    const currentWord = typeof wordItem === 'string' ? wordItem : wordItem.text

    // 最初の入力時に計測開始
    if (this.isFirstInput) {
      this.lessonStartTime = new Date()
      this.isFirstInput = false
    }

    // エラー状態の場合は何もしない
    if (this.hasError) {
      return
    }

    // 期待される文字
    const expectedChar = currentWord[this.currentPosition]

    // タイプ数をカウント
    this.typedChars++

    if (char === expectedChar) {
      // 正しい入力
      this.currentPosition++
      this.updateDisplay()
      this.highlightNextKey()

      // 単語を完全に入力したら次の単語へ
      if (this.currentPosition === currentWord.length) {
        setTimeout(() => this.nextWord(), 300)
      }
    } else {
      // 間違った入力
      this.hasError = true
      this.mistakeCount++
      this.updateDisplay()
    }
  }

  // 日本語レッスンの文字入力処理
  handleJapaneseCharInput(char) {
    const currentWordData = this.japaneseWords[this.currentWordValue]

    // 最初の入力時に計測開始
    if (this.isFirstInput) {
      this.lessonStartTime = new Date()
      this.isFirstInput = false
    }

    // エラー状態の場合は何もしない
    if (this.hasError) {
      return
    }

    // 期待される文字
    const expectedChar = currentWordData.currentRomaji[currentWordData.romajiPosition]

    // タイプ数をカウント
    this.typedChars++

    // 現在までの入力を取得
    const currentInput = this.getCurrentInput() + char

    if (char === expectedChar) {
      // 正しい入力
      currentWordData.romajiPosition++
      this.updateDisplay()
      this.highlightNextKey()

      // 単語を完全に入力したら次の単語へ
      if (currentWordData.romajiPosition === currentWordData.currentRomaji.length) {
        setTimeout(() => this.nextWord(), 300)
      }
    } else {
      // 期待と異なる場合、別のパターンを試す
      const newPattern = this.tryAlternativePattern(currentWordData, currentInput)
      if (newPattern) {
        // 別のパターンが見つかった場合は切り替える
        currentWordData.currentRomaji = newPattern
        currentWordData.romajiPosition++
        this.updateDisplay()
        this.highlightNextKey()
      } else {
        // どのパターンにも合わない場合はエラー
        this.hasError = true
        this.mistakeCount++
        this.updateDisplay()
      }
    }
  }

  // 別のローマ字パターンを試す（複数パターン対応）
  tryAlternativePattern(currentWordData, typedInput) {
    const romajiData = currentWordData.romajiData
    let position = 0

    // 各かな文字のパターンを試行し、typedInputにマッチするパターンを構築
    for (let i = 0; i < romajiData.length; i++) {
      const kanaItem = romajiData[i]
      let matchedPattern = null

      // このかな文字の各ローマ字パターンを試す
      for (const pattern of kanaItem.roma) {
        const patternLower = pattern.toLowerCase()
        const remainingInput = typedInput.slice(position)

        // このパターンが入力の残り部分の先頭にマッチするか確認
        if (remainingInput.startsWith(patternLower)) {
          matchedPattern = pattern
          position += patternLower.length
          break
        } else if (patternLower.startsWith(remainingInput) && remainingInput.length > 0) {
          // 入力途中の場合（例: "c" が "co" の途中）
          matchedPattern = pattern
          position += remainingInput.length  // 部分マッチでもpositionを進める
          break
        } else if (remainingInput.length === 0) {
          // まだ入力されていない部分（デフォルトパターンを使用）
          matchedPattern = pattern
          break
        }
      }

      if (!matchedPattern) {
        // どのパターンにもマッチしない場合
        return null
      }
    }

    // 全てのかな文字がマッチした場合、新しいローマ字文字列を生成
    let newRomaji = ''
    position = 0

    for (let i = 0; i < romajiData.length; i++) {
      const kanaItem = romajiData[i]
      let selectedPattern = kanaItem.roma[0] // デフォルト

      for (const pattern of kanaItem.roma) {
        const patternLower = pattern.toLowerCase()
        const remainingInput = typedInput.slice(position)

        if (remainingInput.startsWith(patternLower) || patternLower.startsWith(remainingInput)) {
          selectedPattern = pattern
          position += Math.min(patternLower.length, remainingInput.length)
          break
        }
      }

      newRomaji += selectedPattern.toLowerCase()
    }

    return newRomaji
  }

  // BackSpace時にローマ字パターンを再構築
  rebuildRomajiPattern(currentWordData, typedInput) {
    if (typedInput.length === 0) {
      // 完全にクリアされた場合はデフォルトパターンに戻す
      const romajiData = currentWordData.romajiData
      currentWordData.currentRomaji = romajiData.map(item => item.roma[0]).join('').toLowerCase()
      return
    }

    // 入力途中の場合は現在の入力にマッチするパターンを再構築
    const newPattern = this.tryAlternativePattern(currentWordData, typedInput)
    if (newPattern) {
      currentWordData.currentRomaji = newPattern
    }
  }

  // 次の単語へ進む
  nextWord() {
    this.currentWordValue += 1
    this.currentPosition = 0
    this.inputTarget.value = ""
    this.hasError = false

    // 日本語レッスンの場合はromajiPositionもリセット
    if (this.isJapaneseLesson && this.japaneseWords[this.currentWordValue]) {
      this.japaneseWords[this.currentWordValue].romajiPosition = 0
    }

    if (this.currentWordValue >= this.words.length) {
      // 全単語完了 - セッション完了画面を表示
      this.showCompletionScreen()
      return
    }

    this.updateDisplay()
    this.highlightNextKey()
  }

  // レッスン完了画面を表示
  showCompletionScreen() {
    // 所要時間を計算
    const endTime = new Date()
    const elapsedMs = endTime - this.lessonStartTime
    const elapsedSeconds = Math.floor(elapsedMs / 1000)
    const minutes = Math.floor(elapsedSeconds / 60)
    const seconds = elapsedSeconds % 60
    const timeString = `${minutes}:${seconds.toString().padStart(2, '0')}`

    // 正答率を計算（タイプした文字数に対するミス数の割合）
    const accuracy = this.typedChars > 0
      ? Math.round(((this.typedChars - this.mistakeCount) / this.typedChars) * 100)
      : 100

    // WPMを計算（CPM = タイプ数 / 秒数 × 60、WPM = CPM / 5）
    const cpm = elapsedSeconds > 0 ? (this.typedChars / elapsedSeconds) * 60 : 0
    const wpm = Math.round(cpm / 5)

    // グレードを判定
    const grade = this.calculateGrade(accuracy, wpm)

    // 統計情報を画面に表示
    this.accuracyDisplayTarget.textContent = `${accuracy}%`
    this.timeDisplayTarget.textContent = timeString
    this.mistakesDisplayTarget.textContent = this.mistakeCount
    this.wpmDisplayTarget.textContent = wpm

    // グレード情報を表示
    // 画像パスを設定（コントローラーから渡された完全なパスを使用）
    this.gradeImageTarget.src = grade.image_path
    this.gradeImageTarget.alt = grade.name
    this.gradeNameTarget.textContent = grade.name
    this.gradeDescriptionTarget.textContent = grade.description

    // 履歴を保存（未ログインユーザーも保存可能）
    this.saveHistory(accuracy, elapsedSeconds)

    // 完了時は警告を解除（ページ遷移を許可）
    this.removeNavigationWarning()

    // 画面を切り替え
    this.lessonScreenTarget.classList.add('hidden')
    this.completionScreenTarget.classList.remove('hidden')
  }

  // グレードを計算（カワウソテーマ・5段階）
  // Rubyの LessonGrades::DEFINITIONS から data-typing-grades-value 経由で取得
  calculateGrade(accuracy, wpm) {
    const grades = this.gradesValue

    // Ruby側のキー名（legendary, adult, young, child, baby）でアクセス
    // accuracy_min, wpm_min は camelCase に変換されている
    if (accuracy >= grades.legendary.accuracy_min && wpm >= grades.legendary.wpm_min) {
      return grades.legendary
    } else if (accuracy >= grades.adult.accuracy_min && wpm >= grades.adult.wpm_min) {
      return grades.adult
    } else if (accuracy >= grades.young.accuracy_min && wpm >= grades.young.wpm_min) {
      return grades.young
    } else if (accuracy >= grades.child.accuracy_min && wpm >= grades.child.wpm_min) {
      return grades.child
    } else {
      return grades.baby
    }
  }

  // 履歴を保存（未ログインユーザーも保存可能）
  async saveHistory(accuracy, durationSeconds) {
    try {
      const response = await fetch('/lesson_records', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          lesson_record: {
            lesson_id: this.lessonInfoValue.lesson_id,
            lesson_name: this.lessonInfoValue.lesson_name,
            word_count: this.words.length,
            correct_count: this.typedChars - this.mistakeCount,
            mistake_count: this.mistakeCount,
            accuracy: accuracy,
            duration_seconds: durationSeconds,
            typed_chars: this.typedChars
          }
        })
      })

      if (response.ok) {
        // レスポンスからlesson_record_idを取得して保存
        const data = await response.json()
        this.savedLessonRecordId = data.lesson_record_id
      } else {
        console.error('Failed to save history:', await response.text())
      }
    } catch (error) {
      console.error('Error saving history:', error)
    }
  }

  // 結果をシェア
  async shareResult() {
    if (!this.savedLessonRecordId) {
      alert('レッスン記録が見つかりません。もう一度練習を完了してください。')
      return
    }

    try {
      const response = await fetch('/shares', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          lesson_record_id: this.savedLessonRecordId
        })
      })

      if (response.ok) {
        const data = await response.json()
        // Xのシェアウィンドウを開く
        window.open(data.twitter_url, '_blank', 'width=550,height=420')
      } else {
        alert('シェアに失敗しました')
      }
    } catch (error) {
      console.error('Share error:', error)
      alert('シェアに失敗しました')
    }
  }

  // レッスンを再開
  restartLesson() {
    // 統計情報をリセット
    this.currentWordValue = 0
    this.currentPosition = 0
    this.hasError = false
    this.mistakeCount = 0
    this.totalKeystrokes = 0
    this.typedChars = 0
    this.lessonStartTime = null // 次の入力時に再設定
    this.isFirstInput = true // 最初の入力フラグをリセット

    // 日本語レッスンの場合はromajiPositionもリセット
    if (this.isJapaneseLesson) {
      this.japaneseWords.forEach(wordData => {
        wordData.romajiPosition = 0
      })
    }

    // 入力欄をクリア
    this.inputTarget.value = ""

    // 画面を切り替え
    this.completionScreenTarget.classList.add('hidden')
    this.lessonScreenTarget.classList.remove('hidden')

    // 表示を更新
    this.updateDisplay()
    this.highlightNextKey()

    // 入力欄にフォーカス
    this.inputTarget.focus()

    // 警告を再設定
    this.setupNavigationWarning()
  }

  // 表示を更新
  updateDisplay() {
    // 日本語レッスンの場合は専用の表示を使用
    if (this.isJapaneseLesson) {
      this.updateJapaneseDisplay()
      return
    }

    // 英語レッスンの場合は既存の表示
    const wordItem = this.words[this.currentWordValue]
    const currentWord = typeof wordItem === 'string' ? wordItem : wordItem.text
    const completed = currentWord.slice(0, this.currentPosition)
    const current = currentWord[this.currentPosition] || ""
    const remaining = currentWord.slice(this.currentPosition + 1)

    // スペースを視覚化する関数
    const displayChar = (char) => char === ' ' ? '␣' : this.escapeHtml(char)

    // 単語表示を更新（常に同じ高さ・幅を保ってレイアウトシフトを防止）
    // 完了/現在/残りの全ての文字に同じパディング・マージンを適用し、色とアンダーラインだけを変える
    const completedChars = completed.split('').map(char =>
      `<span class="inline-block text-center px-2 py-1 mb-1 font-semibold text-green-600 dark:text-green-400">${displayChar(char)}</span>`
    ).join('')

    const remainingChars = remaining.split('').map(char =>
      `<span class="inline-block text-center px-2 py-1 mb-1 text-gray-400 dark:text-gray-500">${displayChar(char)}</span>`
    ).join('')

    if (!current) {
      // 単語の最後に達した場合: 完了した文字のみ表示
      this.displayTarget.innerHTML = completedChars
    } else if (this.hasError) {
      // ミスタイプ時: 現在の文字を赤く表示
      this.displayTarget.innerHTML = `
        ${completedChars}<span class="inline-block text-center px-2 py-1 mb-1 bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300 border-b-4 border-red-600 dark:border-red-400 font-bold rounded animate-shake">${displayChar(current)}</span>${remainingChars}
      `
    } else {
      // 通常時: 現在の文字を青く表示
      this.displayTarget.innerHTML = `
        ${completedChars}<span class="inline-block text-center px-2 py-1 mb-1 bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300 font-bold rounded relative"><span class="border-b-4 border-blue-600 dark:border-blue-400 animate-blink-underline">${displayChar(current)}</span></span>${remainingChars}
      `
    }

    // 進捗表示を更新
    this.progressTarget.textContent = `問題 ${this.currentWordValue + 1} / ${this.words.length}`
  }

  // 日本語表示を更新（3段表示: ひらがな・本文・ローマ字）
  updateJapaneseDisplay() {
    const currentWordData = this.japaneseWords[this.currentWordValue]
    const romajiPos = currentWordData.romajiPosition
    const currentRomaji = currentWordData.currentRomaji

    // ローマ字の表示（下段、既存のロジックを流用）
    const romajiCompleted = currentRomaji.slice(0, romajiPos)
    const romajiCurrent = currentRomaji[romajiPos] || ""
    const romajiRemaining = currentRomaji.slice(romajiPos + 1)

    const displayChar = (char) => char === ' ' ? '␣' : this.escapeHtml(char)

    const romajiCompletedChars = romajiCompleted.split('').map(char =>
      `<span class="inline-block text-center px-1 font-semibold text-green-600 dark:text-green-400">${displayChar(char)}</span>`
    ).join('')

    const romajiRemainingChars = romajiRemaining.split('').map(char =>
      `<span class="inline-block text-center px-1 text-gray-400 dark:text-gray-500">${displayChar(char)}</span>`
    ).join('')

    let romajiHTML = ''
    if (!romajiCurrent) {
      romajiHTML = romajiCompletedChars
    } else if (this.hasError) {
      romajiHTML = `
        ${romajiCompletedChars}<span class="inline-block text-center px-1 bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300 border-b-2 border-red-600 dark:border-red-400 font-bold rounded animate-shake">${displayChar(romajiCurrent)}</span>${romajiRemainingChars}
      `
    } else {
      romajiHTML = `
        ${romajiCompletedChars}<span class="inline-block text-center px-1 bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300 font-bold rounded relative"><span class="border-b-2 border-blue-600 dark:border-blue-400 animate-blink-underline">${displayChar(romajiCurrent)}</span></span>${romajiRemainingChars}
      `
    }

    // displayフィールドがある場合はそれを使用、なければoriginalを使用
    const displayText = currentWordData.display || currentWordData.original

    // 最上段: ひらがな読み（小さく）
    // 中段: 表示用テキスト（大きく、メイン表示）- displayフィールドがあれば漢字・カタカナ混じり
    // 下段: ローマ字ガイド（小さく）
    this.displayTarget.innerHTML = `
      <div class="flex flex-col items-center gap-2">
        <div class="text-sm text-gray-500 dark:text-gray-400">${this.escapeHtml(currentWordData.original)}</div>
        <div class="text-5xl font-mono tracking-wider">${this.escapeHtml(displayText)}</div>
        <div class="text-base font-mono tracking-wide text-gray-600 dark:text-gray-300">${romajiHTML}</div>
      </div>
    `

    // 進捗表示を更新
    this.progressTarget.textContent = `問題 ${this.currentWordValue + 1} / ${this.words.length}`
  }

  // HTMLエスケープ用ヘルパー
  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  // キーボードに指ごとの色を適用し、全レイヤーのデータを保存
  applyFingerColors() {
    Object.entries(this.fingerPositionMapping).forEach(([finger, positions]) => {
      const colors = this.fingerColors[finger]
      positions.forEach(position => {
        const keyElement = document.querySelector(`.key[data-position="${position}"]`)
        if (keyElement) {
          // bg-white と dark:bg-gray-700 を削除して、指ごとの色（薄い色）を追加
          keyElement.classList.remove('bg-white', 'dark:bg-gray-700')
          // 複数のクラスを一度に追加（スペース区切りを分割）
          colors.light.split(' ').forEach(cls => keyElement.classList.add(cls))
          // data属性に指情報を保存
          keyElement.dataset.finger = finger

          // 全レイヤーの文字データを保存（data-layer-0, data-layer-1, ...）
          for (let layer = 0; layer < 6; layer++) {
            const layerData = this.keymapsValue[layer] || this.keymapsValue[layer.toString()] || {}
            const char = layerData[position] || ''
            keyElement.dataset[`layer${layer}`] = char
          }
        }
      })
    })
  }

  // キーボード表示を指定レイヤーに切り替え
  switchKeyboardLayer(layer) {
    this.currentLayer = layer

    // 全てのキーの表示を更新
    document.querySelectorAll('.key[data-position]').forEach(keyElement => {
      const char = keyElement.dataset[`layer${layer}`] || ''
      // 2段表示のHTMLを生成
      keyElement.innerHTML = this.formatKeyDisplay(char)

      // blankの場合は親要素に背景を設定
      if (char && char.toLowerCase() === 'blank') {
        keyElement.classList.add('bg-gray-600', 'dark:bg-gray-800')
        keyElement.classList.remove('bg-white', 'dark:bg-gray-700', 'bg-red-100', 'bg-yellow-100', 'bg-blue-100', 'bg-green-100', 'bg-gray-100')
      } else {
        keyElement.classList.remove('bg-gray-600', 'dark:bg-gray-800')
        // 指の色は highlightKey メソッドで設定されるのでここでは削除のみ
      }
    })
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

    // "Q q" や "! 1" 形式（半角スペース区切り）、または "Q|q" や "!|1" 形式（|区切り、後方互換性）の場合は2段表示
    // 上段: 小さめ・グレー、下段: 大きめ・太字・黒
    if (char.includes(' ') || char.includes('|')) {
      // 半角スペース区切りを優先、なければ|区切り
      const delimiter = char.includes(' ') ? ' ' : '|'
      const parts = char.split(delimiter)
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

  // 次に打つべきキーをハイライト（レイヤー自動判定付き）
  highlightNextKey() {
    // 以前のハイライトを全て解除（全てのキーを薄い色に戻す）
    document.querySelectorAll('.key[data-finger]').forEach(key => {
      const finger = key.dataset.finger
      const colors = this.fingerColors[finger]
      if (colors) {
        // 濃い色を削除して薄い色に戻す（スペース区切りのクラスを適切に処理）
        colors.dark.split(' ').forEach(cls => key.classList.remove(cls))
        colors.light.split(' ').forEach(cls => {
          if (!key.classList.contains(cls)) {
            key.classList.add(cls)
          }
        })
        // リングも削除
        key.classList.remove('ring-2')
      }
    })

    // 指ガイドのハイライトも解除（濃い色だけ削除、薄い色は維持）
    document.querySelectorAll('.finger-guide').forEach(guide => {
      const finger = guide.dataset.finger
      const colors = this.fingerColors[finger]
      if (colors) {
        // 濃い色を削除（スペース区切りのクラスを適切に処理）
        colors.dark.split(' ').forEach(cls => guide.classList.remove(cls))
        // 薄い色を追加（もし削除されていた場合のために）
        colors.light.split(' ').forEach(cls => {
          if (!guide.classList.contains(cls)) {
            guide.classList.add(cls)
          }
        })
        // リングを削除
        guide.classList.remove('ring-2')
      }
    })

    // 次に打つべき文字を取得
    let nextChar
    if (this.isJapaneseLesson) {
      // 日本語の場合はローマ字の次の文字
      const currentWordData = this.japaneseWords[this.currentWordValue]
      nextChar = currentWordData.currentRomaji[currentWordData.romajiPosition]
    } else {
      // 英語の場合は通常の文字
      const wordItem = this.words[this.currentWordValue]
      const currentWord = typeof wordItem === 'string' ? wordItem : wordItem.text
      nextChar = currentWord[this.currentPosition]
    }

    if (!nextChar) return // 単語の終わりに達した場合

    // キーマップから対応するキー位置を取得（全レイヤーから検索）
    const keyMappings = this.keyMapping[nextChar.toLowerCase()]

    if (!keyMappings || keyMappings.length === 0) {
      console.warn(`Character "${nextChar}" not found in any layer`)
      return
    }

    // 優先順位: Layer 0 > Layer 1 > ... の順で検索
    const targetMapping = keyMappings[0]
    const targetLayer = targetMapping.layer
    const targetPosition = targetMapping.position
    const displayChar = targetMapping.displayChar

    // レイヤー切り替えが必要な場合はキーボード表示を更新
    if (targetLayer !== this.currentLayer) {
      this.switchKeyboardLayer(targetLayer)
    }

    // 2段表示のキーで、上段の文字を入力する場合はShiftキーもハイライト
    const needsShift = this.needsShiftKey(nextChar, displayChar)

    // 1. 目的の文字キー: 同じレイヤー内で同じ文字のキーを全て探してハイライト
    const mainKeyPositions = this.findAllMatchingKeys(nextChar, targetLayer)
    mainKeyPositions.forEach(pos => this.highlightKey(pos))

    // 2. Shiftキー: Layer 0で'shift'を全て探してハイライト
    if (needsShift) {
      const shiftPositions = this.findAllMatchingKeys('shift', 0)
      shiftPositions.forEach(pos => this.highlightKey(pos))
    }

    // 3. レイヤーキー: Layer 0でレイヤーキーを全て探してハイライト
    if (targetLayer > 0) {
      const layerKeyPositions = this.findAllLayerKeyPositions(targetLayer)
      layerKeyPositions.forEach(pos => this.highlightKey(pos))
    }
  }

  // Shiftキーが必要かどうかを判定
  // @param nextChar - 次に入力する文字
  // @param displayChar - キーの表示文字（"Q q"や"! 1"など）
  // @return true: Shiftキーが必要、false: 不要
  needsShiftKey(nextChar, displayChar) {
    // 2段表示でない場合はShift不要
    if (!displayChar.includes(' ') && !displayChar.includes('|')) {
      return false
    }

    // 区切り文字を判定
    const delimiter = displayChar.includes(' ') ? ' ' : '|'
    const parts = displayChar.split(delimiter)
    const upperChar = parts[0] // 上段の文字

    // 次の文字が上段の文字と一致する場合、Shift必要
    return nextChar === upperChar
  }

  // 指定レイヤーで指定文字に一致する全キーの位置を返す
  // @param targetChar - 探す文字（例: 'a', 'shift', '1'）
  // @param layer - 探すレイヤー番号
  // @return Array<string> - マッチしたキーの位置の配列
  findAllMatchingKeys(targetChar, layer) {
    const layerData = this.keymapsValue[layer] || this.keymapsValue[layer.toString()] || {}
    const positions = []

    for (const [position, char] of Object.entries(layerData)) {
      if (this.isCharMatch(char, targetChar)) {
        positions.push(position)
      }
    }

    return positions
  }

  // 文字マッチング判定（2段表示対応）
  // @param keyChar - キーに割り当てられた文字（例: "Q q", "! 1", "shift"）
  // @param targetChar - 探す文字
  // @return boolean - マッチするかどうか
  isCharMatch(keyChar, targetChar) {
    if (!keyChar) return false

    const keyCharLower = keyChar.toLowerCase()
    const targetCharLower = targetChar.toLowerCase()

    // 2段表示の場合（"Q q"や"! 1"など）
    if (keyChar.includes(' ') || keyChar.includes('|')) {
      const delimiter = keyChar.includes(' ') ? ' ' : '|'
      const parts = keyChar.split(delimiter)
      // 上段または下段のいずれかがマッチすればOK
      return parts.some(part => part.toLowerCase() === targetCharLower)
    }

    // 通常の1段表示の場合
    return keyCharLower === targetCharLower
  }

  // 指定レイヤーに対応するレイヤーキーの位置を全て返す
  // @param layer - レイヤー番号（1-5）
  // @return Array<string> - マッチしたレイヤーキーの位置の配列
  findAllLayerKeyPositions(layer) {
    // Layer 1-5 のボタン候補
    // 基本の候補: layer1, lyr1 など
    const layerKeys = [`layer${layer}`, `lyr${layer}`]

    // Layer 1と2の場合のみ、lower/raiseも候補に追加（QMK慣習）
    if (layer === 1) {
      layerKeys.push('lower')
    } else if (layer === 2) {
      layerKeys.push('raise')
    }

    const positions = []
    const currentLayerData = this.keymapsValue[0] || this.keymapsValue["0"] || {}

    for (const [position, char] of Object.entries(currentLayerData)) {
      if (char && layerKeys.includes(char.toLowerCase())) {
        positions.push(position)
      }
    }

    return positions
  }

  // 指定されたキーをハイライト
  highlightKey(position) {
    const keyElement = document.querySelector(`.key[data-position="${position}"]`)
    if (keyElement) {
      const targetFinger = keyElement.dataset.finger
      if (targetFinger) {
        const colors = this.fingerColors[targetFinger]

        // キーを濃い色にする（スペース区切りのクラスを適切に削除/追加）
        colors.light.split(' ').forEach(cls => keyElement.classList.remove(cls))
        colors.dark.split(' ').forEach(cls => keyElement.classList.add(cls))
        keyElement.classList.add('ring-2')

        // 指ガイドも濃い色にする
        const guideElement = document.querySelector(`.finger-guide[data-finger="${targetFinger}"]`)
        if (guideElement) {
          colors.light.split(' ').forEach(cls => guideElement.classList.remove(cls))
          colors.dark.split(' ').forEach(cls => guideElement.classList.add(cls))
          guideElement.classList.add('ring-2')
        }
      }
    }
  }

  // ページ離脱警告の設定
  setupNavigationWarning() {
    // 1. ブラウザを閉じる・リロード・戻るボタン時の警告
    this.handleBeforeUnload = (event) => {
      if (this.isLessonInProgress()) {
        event.preventDefault()
        event.returnValue = '' // Chrome用（標準メッセージが表示される）
        return '' // 他のブラウザ用
      }
    }
    window.addEventListener('beforeunload', this.handleBeforeUnload)

    // 2. Turboナビゲーション（アプリ内リンククリック）時の警告
    this.handleBeforeVisit = (event) => {
      if (this.isLessonInProgress()) {
        if (!confirm('画面を移動すると練習は記録されません。移動しますか？')) {
          event.preventDefault()
        }
      }
    }
    document.addEventListener('turbo:before-visit', this.handleBeforeVisit)
  }

  // ページ離脱警告の解除
  removeNavigationWarning() {
    if (this.handleBeforeUnload) {
      window.removeEventListener('beforeunload', this.handleBeforeUnload)
      this.handleBeforeUnload = null
    }
    if (this.handleBeforeVisit) {
      document.removeEventListener('turbo:before-visit', this.handleBeforeVisit)
      this.handleBeforeVisit = null
    }
  }

  // 練習中かどうかを判定
  isLessonInProgress() {
    // 完了画面が表示されている = 練習完了 = 警告不要
    const isCompleted = !this.completionScreenTarget.classList.contains('hidden')
    if (isCompleted) {
      return false
    }

    // まだ全単語を完了していない = 練習中 = 警告必要
    return this.currentWordValue < this.wordsValue.length
  }

  // ヘルパー: 単語リスト取得
  get words() {
    return this.wordsValue
  }
}
