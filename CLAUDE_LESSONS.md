# CLAUDE_LESSONS.md

このドキュメントは、Typnixの練習レッスンの全体像を管理するためのインデックスです。

## 📋 レッスン構成の方針

### タブ構成（2階層分類）

レッスンは**タブ（1階層目）** → **カテゴリー（2階層目）** の2階層で分類します。

#### 1階層目: タブ

1. **基礎トレーニング** 🔰
   - キー配置の練習
   - 指別の強化トレーニング
   - 全言語の基礎をまとめて提供

2. **英語練習**
   - 英単語（難易度別）
   - テーマ別単語
   - 短文・フレーズ

3. **日本語練習** ⭐準備中
   - かな入力
   - ローマ字入力
   - テーマ別・短文

4. **プログラミング**
   - 言語別用語
   - コード・フレーズ
   - 数字・記号コード

#### 2階層目: カテゴリー（タブ内の分類）

各タブ内で、さらに細かくカテゴリー分けを行います。詳細は後述の「タブ・カテゴリー対応表」を参照。

---

## 🎯 現在登録されているレッスン（DB化済み）

以下のレッスンは、Day 21に `config/typing_lessons.yml` からデータベースに移行済みです。

---

## 📊 タブ・カテゴリー対応表

### タブ1: 基礎トレーニング 🔰

#### カテゴリー1-1: 基礎練習

**カテゴリー設定:**
- `requires_login: false`
- `premium: false`
- `published: true`

**レッスン一覧:**
- [Lesson 1: 上段キー](lessons/1_basics/01_upper_row.md) - qwertyuiop の練習
- [Lesson 2: ホームポジション](lessons/1_basics/02_home_position.md) - asdfghjkl の練習
- [Lesson 3: 下段キー](lessons/1_basics/03_lower_row.md) - zxcvbnm の練習

#### カテゴリー1-2: 指別練習

**カテゴリー設定:**
- `requires_login: false`
- `premium: false`
- `published: true`

**レッスン一覧:**
- [Lesson 4: 左手中心](lessons/1_basics/04_left_hand.md) - 左手で打ちやすい単語
- [Lesson 5: 右手中心](lessons/1_basics/05_right_hand.md) - 右手で打ちやすい単語
- [Lesson 6: 小指強化](lessons/1_basics/06_pinky.md) - 小指を使うキーの練習

---

### タブ2: 英語練習

#### カテゴリー2-1: 単語練習

**カテゴリー設定:**
- `requires_login: false`
- `premium: false`
- `published: true`

**レッスン一覧:**
- [Lesson 7: 初級単語](lessons/2_english/07_beginner_words.md) - 短くて簡単な単語（30語）
- [Lesson 8: 中級単語](lessons/2_english/08_intermediate_words.md) - やや長めの単語（30語）
- [Lesson 9: 上級単語](lessons/2_english/09_advanced_words.md) - 長くて複雑な単語（30語）

#### カテゴリー2-2: テーマ別

**カテゴリー設定:**
- `requires_login: true`
- `premium: false`
- `published: true`

**レッスン一覧:**
- [Lesson 12: 果物](lessons/2_english/12_fruits.md) - 果物の名前（20語）
- [Lesson 13: 天気](lessons/2_english/13_weather.md) - 天気に関する単語（20語）
- [Lesson 14: ありがちな人名](lessons/2_english/14_names.md) - 英語圏の一般的な名前（20語）

#### カテゴリー2-3: 短文練習

**カテゴリー設定:**
- `requires_login: true`
- `premium: false`
- `published: true`

**レッスン一覧:**
- [Lesson 15: 3-5語の短文](lessons/2_english/15_short_sentences.md) - よく使うフレーズ（15文）

---

### タブ3: 日本語練習 ⭐準備中

（将来実装予定）

---

### タブ4: プログラミング

#### カテゴリー4-1: テーマ別

**カテゴリー設定:**
- `requires_login: true`
- `premium: false`
- `published: true`

**レッスン一覧:**
- [Lesson 10: Ruby用語](lessons/4_programming/10_ruby.md) - Ruby言語の用語（25語）
- [Lesson 11: Web用語](lessons/4_programming/11_web.md) - Web開発の用語（25語）

#### カテゴリー4-2: 短文練習

**カテゴリー設定:**
- `requires_login: true`
- `premium: false`
- `published: true`

**レッスン一覧:**
- [Lesson 16: プログラミングフレーズ](lessons/4_programming/16_programming_phrases.md) - コードでよく使う表現（15文）

---

## 🔮 今後追加予定のレッスン

### 追加予定1: 数字・記号練習（Day 22-23）

**背景:**
- キーマップ編集画面に数字・記号の単体選択肢を追加（Day 22完了）
- 数字・記号を含む練習問題の追加が必要

**カテゴリー案:**
- **Category名**: 数字・記号練習
- `requires_login: false`（または `true`）
- `premium: false`
- `published: true`

**レッスン案:**

#### Lesson 17: 数字練習（案）
- **説明**: 0-9の数字を練習
- **出題数**: 20
- **内容**: 検討中（具体的な出題形式を決める必要あり）

#### Lesson 18: 記号練習（案）
- **説明**: プログラミングでよく使う記号
- **出題数**: 20
- **内容**: 検討中（具体的な出題形式を決める必要あり）

#### Lesson 19: 数字+記号混合（案）
- **説明**: 数字と記号を含む実践的な練習
- **出題数**: 20
- **内容**: 検討中

**検討事項:**
1. 出題形式: ランダムな数字の羅列？それとも意味のある数値（西暦、電話番号など）？
2. 記号の種類: プログラミング記号に絞る？それとも全記号？
3. 難易度: 初級・中級・上級に分けるか？

---

## 🎯 レッスン設計のガイドライン

### カテゴリーの権限設計

1. **ログイン不要（`requires_login: false`）**:
   - 基礎練習、指別練習、単語練習（初級〜上級）
   - サービスのお試し体験として重要

2. **ログイン必要（`requires_login: true`）**:
   - プログラミング、テーマ別、短文練習
   - ユーザー登録を促すための価値提供

3. **課金必要（`premium: true`）**:
   - 現在は未使用
   - 将来的な拡張に備えて予約

### レッスンの難易度設計

1. **初級**: 3-5文字の短い単語、基本的なキー配置
2. **中級**: 6-10文字の単語、組み合わせパターン
3. **上級**: 10文字以上の長い単語、複雑な組み合わせ

### 出題数の目安

- **基礎練習**: 20問
- **単語練習**: 20-30問
- **短文練習**: 15問

---

## 🗂️ ファイル構成

レッスンの詳細は、以下のディレクトリ構造で管理されています:

```
docs/lessons/
├── 1_basics/          # 基礎トレーニング（Lesson 1-6）
├── 2_english/         # 英語練習（Lesson 7-9, 12-15）
├── 3_japanese/        # 日本語練習（準備中）
└── 4_programming/     # プログラミング（Lesson 10-11, 16）
```

各レッスンファイルには以下の情報が含まれます:
- 基本情報（説明、出題数、カテゴリー）
- 権限設定（requires_login, premium, published）
- 完全な単語/文章リスト

---

## 🔄 移行履歴

- **Day 21**: `config/typing_lessons.yml` → PostgreSQL（Category・Lessonモデル）に移行完了
- **Day 22**: `config/typing_lessons.yml` → `CLAUDE_LESSONS.md` に移行、YAMLファイル削除
- **Day 22**: レッスンを個別ファイルに分割、`CLAUDE_LESSONS.md` をインデックス化
