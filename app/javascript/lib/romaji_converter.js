// ひらがな → ローマ字変換テーブル
// 複数の入力パターンを配列で定義（優先度順）

export const ROMAJI_MAP = {
  // 清音
  'あ': ['a'],
  'い': ['i'],
  'う': ['u'],
  'え': ['e'],
  'お': ['o'],

  'か': ['ka', 'ca'],
  'き': ['ki'],
  'く': ['ku', 'cu'],
  'け': ['ke'],
  'こ': ['ko', 'co'],

  'さ': ['sa'],
  'し': ['si', 'shi', 'ci'],
  'す': ['su'],
  'せ': ['se', 'ce'],
  'そ': ['so'],

  'た': ['ta'],
  'ち': ['ti', 'chi'],
  'つ': ['tu', 'tsu'],
  'て': ['te'],
  'と': ['to'],

  'な': ['na'],
  'に': ['ni'],
  'ぬ': ['nu'],
  'ね': ['ne'],
  'の': ['no'],

  'は': ['ha'],
  'ひ': ['hi'],
  'ふ': ['hu', 'fu'],
  'へ': ['he'],
  'ほ': ['ho'],

  'ま': ['ma'],
  'み': ['mi'],
  'む': ['mu'],
  'め': ['me'],
  'も': ['mo'],

  'や': ['ya'],
  'ゆ': ['yu'],
  'よ': ['yo'],

  'ら': ['ra'],
  'り': ['ri'],
  'る': ['ru'],
  'れ': ['re'],
  'ろ': ['ro'],

  'わ': ['wa'],
  'を': ['wo'],
  'ん': ['nn', 'xn'],

  // 濁音
  'が': ['ga'],
  'ぎ': ['gi'],
  'ぐ': ['gu'],
  'げ': ['ge'],
  'ご': ['go'],

  'ざ': ['za'],
  'じ': ['zi', 'ji'],
  'ず': ['zu'],
  'ぜ': ['ze'],
  'ぞ': ['zo'],

  'だ': ['da'],
  'ぢ': ['di'],
  'づ': ['du'],
  'で': ['de'],
  'ど': ['do'],

  'ば': ['ba'],
  'び': ['bi'],
  'ぶ': ['bu'],
  'べ': ['be'],
  'ぼ': ['bo'],

  // 半濁音
  'ぱ': ['pa'],
  'ぴ': ['pi'],
  'ぷ': ['pu'],
  'ぺ': ['pe'],
  'ぽ': ['po'],

  // 拗音（きゃ、きゅ、きょ系）
  'きゃ': ['kya'],
  'きゅ': ['kyu'],
  'きょ': ['kyo'],

  'ぎゃ': ['gya'],
  'ぎゅ': ['gyu'],
  'ぎょ': ['gyo'],

  'しゃ': ['sya', 'sha'],
  'しゅ': ['syu', 'shu'],
  'しぇ': ['sye', 'she'],
  'しょ': ['syo', 'sho'],

  'じゃ': ['ja', 'jya'],
  'じゅ': ['ju', 'jyu'],
  'じぇ': ['je', 'jye'],
  'じょ': ['jo', 'jyo'],

  'ちゃ': ['tya', 'cha'],
  'ちゅ': ['tyu', 'chu'],
  'ちぇ': ['tye', 'che'],
  'ちょ': ['tyo', 'cho'],

  'ぢゃ': ['dya'],
  'ぢゅ': ['dyu'],
  'ぢょ': ['dyo'],

  'にゃ': ['nya'],
  'にゅ': ['nyu'],
  'にょ': ['nyo'],

  'ひゃ': ['hya'],
  'ひゅ': ['hyu'],
  'ひょ': ['hyo'],

  'びゃ': ['bya'],
  'びゅ': ['byu'],
  'びょ': ['byo'],

  'ぴゃ': ['pya'],
  'ぴゅ': ['pyu'],
  'ぴょ': ['pyo'],

  'ふぁ': ['fa'],
  'ふぃ': ['fi'],
  'ふぇ': ['fe'],
  'ふぉ': ['fo'],
  'ふゃ': ['fya'],
  'ふゅ': ['fyu'],
  'ふょ': ['fyo'],

  'みゃ': ['mya'],
  'みゅ': ['myu'],
  'みょ': ['myo'],

  'りゃ': ['rya'],
  'りゅ': ['ryu'],
  'りょ': ['ryo'],

  // 促音（小さい「っ」）
  'っ': ['xtu', 'ltu'],

  // 小書き文字
  'ぁ': ['xa', 'la'],
  'ぃ': ['xi', 'li'],
  'ぅ': ['xu', 'lu'],
  'ぇ': ['xe', 'le'],
  'ぉ': ['xo', 'lo'],

  'ゃ': ['xya', 'lya'],
  'ゅ': ['xyu', 'lyu'],
  'ょ': ['xyo', 'lyo'],
  'ゎ': ['xwa', 'lwa'],

  // その他
  'うぁ': ['wha'],
  'うぃ': ['wi'],
  'うぇ': ['we'],
  'うぉ': ['who'],

  'ゔぁ': ['va'],
  'ゔぃ': ['vi'],
  'ゔ': ['vu'],
  'ゔぇ': ['ve'],
  'ゔぉ': ['vo'],

  'てぃ': ['thi'],
  'でぃ': ['dhi'],
  'でゅ': ['dhu'],

  // 記号（ローマ字入力で使う実際のキー）
  'ー': ['-'],           // 長音符
  '、': [','],           // 読点
  '。': ['.'],           // 句点
  '「': ['['],           // かぎかっこ開く
  '」': [']'],           // かぎかっこ閉じる
  '・': ['/'],           // 中点
  '！': ['!'],           // 感嘆符
  '？': ['?'],           // 疑問符
  '（': ['('],           // 丸括弧開く
  '）': [')'],           // 丸括弧閉じる
  '～': ['~'],           // 波ダッシュ

  // 全角数字（0-9）
  '０': ['0'],
  '１': ['1'],
  '２': ['2'],
  '３': ['3'],
  '４': ['4'],
  '５': ['5'],
  '６': ['6'],
  '７': ['7'],
  '８': ['8'],
  '９': ['9'],

  // Shift + 数字キーで入力する記号
  '＠': ['@'],           // Shift + 2
  '＃': ['#'],           // Shift + 3
  '＄': ['$'],           // Shift + 4
  '％': ['%'],           // Shift + 5
  '＾': ['^'],           // Shift + 6
  '＆': ['&'],           // Shift + 7
  '＊': ['*'],           // Shift + 8

  // その他の記号
  '＋': ['+'],           // +
  '＝': ['='],           // =
  '＿': ['_'],           // Shift + -
  '｜': ['|'],           // Shift + \
  '：': [':'],           // Shift + ;
  '；': [';'],           // ;
  '＜': ['<'],           // Shift + ,
  '＞': ['>'],           // Shift + .
  '｛': ['{'],           // Shift + [
  '｝': ['}'],           // Shift + ]
  '＂': ['"'],           // Shift + '
  '＇': ["'"],           // '
  '｀': ['`']            // `
  // 注: 全角スラッシュ（／）と全角バックスラッシュ（＼）は、
  // IME無効化環境では通常の方法で入力できないため対応していません
}

/**
 * ひらがな文字列をローマ字に変換
 * @param {string} hiragana - ひらがな文字列
 * @returns {Array<{kana: string, roma: Array<string>}>} - 各文字のローマ字パターン配列
 */
export function convertToRomaji(hiragana) {
  const result = []
  let i = 0

  while (i < hiragana.length) {
    // 3文字マッチを試行（拗音など）
    if (i + 2 < hiragana.length) {
      const threeChar = hiragana.substring(i, i + 3)
      if (ROMAJI_MAP[threeChar]) {
        result.push({
          kana: threeChar,
          roma: ROMAJI_MAP[threeChar]
        })
        i += 3
        continue
      }
    }

    // 2文字マッチを試行（拗音など）
    if (i + 1 < hiragana.length) {
      const twoChar = hiragana.substring(i, i + 2)
      if (ROMAJI_MAP[twoChar]) {
        result.push({
          kana: twoChar,
          roma: ROMAJI_MAP[twoChar]
        })
        i += 2
        continue
      }
    }

    // 1文字マッチ
    const oneChar = hiragana[i]

    // 促音「っ」の特殊処理
    if (oneChar === 'っ') {
      // 次の文字の子音を取得
      if (i + 1 < hiragana.length) {
        const nextChar = hiragana[i + 1]
        const nextRoma = ROMAJI_MAP[nextChar]
        if (nextRoma && nextRoma[0]) {
          // 次の文字の最初の子音を使用
          const consonant = nextRoma[0][0]
          result.push({
            kana: 'っ',
            roma: [consonant] // 子音1文字
          })
          i++
          continue
        }
      }
      // 次の文字がない場合は通常の「っ」として扱う
      result.push({
        kana: 'っ',
        roma: ['xtu', 'ltu']
      })
      i++
      continue
    }

    // 撥音「ん」の特殊処理
    if (oneChar === 'ん') {
      // 次の文字が子音で始まる場合、単一の'n'も許容する
      if (i + 1 < hiragana.length) {
        const nextChar = hiragana[i + 1]
        const nextRoma = ROMAJI_MAP[nextChar]
        if (nextRoma && nextRoma[0]) {
          // 次の文字の最初の音（子音または母音）をチェック
          const firstSound = nextRoma[0][0]
          // 子音（母音以外）で始まる場合、'n'を追加
          const vowels = ['a', 'i', 'u', 'e', 'o']
          if (!vowels.includes(firstSound)) {
            result.push({
              kana: 'ん',
              roma: ['nn', 'n', 'xn'] // 子音の前では'n'も許容
            })
            i++
            continue
          }
        }
      }
      // 次の文字が母音で始まる場合、または次の文字がない場合は通常の「ん」
      result.push({
        kana: 'ん',
        roma: ['nn', 'xn']
      })
      i++
      continue
    }

    // 通常の1文字変換
    if (ROMAJI_MAP[oneChar]) {
      result.push({
        kana: oneChar,
        roma: ROMAJI_MAP[oneChar]
      })
    } else {
      // マッピングにない文字（漢字など）はそのまま保持
      result.push({
        kana: oneChar,
        roma: [oneChar] // そのまま使用（後で処理する）
      })
    }
    i++
  }

  return result
}

/**
 * ローマ字パターン配列から最初のパターンを連結した文字列を生成
 * @param {Array<{kana: string, roma: Array<string>}>} romajiData
 * @returns {string} - ローマ字文字列（例: "shourishita"、小文字）
 */
export function getDefaultRomajiString(romajiData) {
  return romajiData
    .map(item => item.roma[0])
    .join('')
    .toLowerCase()
}

/**
 * 日本語文字列かどうかを判定（ひらがな・カタカナ・漢字を含むか）
 * @param {string} text
 * @returns {boolean}
 */
export function isJapaneseText(text) {
  // ひらがな（U+3040-U+309F）、カタカナ（U+30A0-U+30FF）、漢字（U+4E00-U+9FFF）
  const japaneseRegex = /[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]/
  return japaneseRegex.test(text)
}
