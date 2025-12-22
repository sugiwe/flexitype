# CLAUDE_LESSONS.md

このドキュメントは、Typnixの練習レッスンの全体像を管理するためのものです。

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

#### カテゴリー1-1: アルファベット基礎（Category: 基礎練習）

**カテゴリー設定:**
- `requires_login: false`
- `premium: false`
- `published: true`

#### Lesson 1: 上段キー
- **説明**: qwertyuiop の練習
- **出題数**: 20
- **単語リスト**（全20語）:
  - qwerty
  - uiop
  - qwe
  - rty
  - uio
  - wer
  - tyu
  - iop
  - qer
  - wrt
  - yui
  - ert
  - tui
  - que
  - poi
  - quit
  - port
  - pour
  - quite
  - quote

#### Lesson 2: ホームポジション
- **説明**: asdfghjkl の練習
- **出題数**: 20
- **単語リスト**（全20語）:
  - asdf
  - ghjkl
  - asd
  - fgh
  - jkl
  - sdf
  - ghj
  - hjk
  - asf
  - dgh
  - jkl
  - sad
  - lad
  - had
  - all
  - fall
  - hall
  - gala
  - salad
  - flask

#### Lesson 3: 下段キー
- **説明**: zxcvbnm の練習
- **出題数**: 20
- **単語リスト**（全20語）:
  - zxcv
  - bnm
  - zxc
  - cvb
  - bnm
  - xcv
  - vbn
  - zxv
  - cvn
  - zcv
  - vbm
  - van
  - can
  - man
  - bam
  - comb
  - bomb
  - calm
  - claim
  - cabin

---

#### カテゴリー1-2: 指別練習（Category: 指別練習）

**カテゴリー設定:**
- `requires_login: false`
- `premium: false`
- `published: true`

#### Lesson 4: 左手中心
- **説明**: 左手で打ちやすい単語
- **出題数**: 20
- **単語リスト**（全20語）:
  - test
  - best
  - west
  - rest
  - read
  - tree
  - free
  - sweet
  - street
  - great
  - bread
  - sewer
  - water
  - aware
  - dress
  - state
  - asset
  - trade
  - crate
  - waste

#### Lesson 5: 右手中心
- **説明**: 右手で打ちやすい単語
- **出題数**: 20
- **単語リスト**（全20語）:
  - join
  - link
  - look
  - moon
  - loop
  - pool
  - pink
  - pump
  - jump
  - limp
  - milk
  - only
  - upon
  - lump
  - plum
  - plump
  - mummy
  - pupil
  - kimono
  - nylon

#### Lesson 6: 小指強化
- **説明**: 小指を使うキーの練習
- **出題数**: 20
- **単語リスト**（全20語）:
  - apple
  - paper
  - peace
  - pizza
  - point
  - power
  - apple
  - upper
  - happy
  - pepper
  - appear
  - proper
  - zipper
  - quality
  - quickly
  - quarter
  - question
  - equality
  - quantity
  - aquarium

---

### タブ2: 英語練習

#### カテゴリー2-1: 単語練習（Category: 単語練習）

**カテゴリー設定:**
- `requires_login: false`
- `premium: false`
- `published: true`

#### Lesson 7: 初級単語
- **説明**: 短くて簡単な単語
- **出題数**: 30
- **単語リスト**（全30語）:
  - apple
  - hello
  - world
  - type
  - code
  - home
  - user
  - data
  - file
  - test
  - view
  - form
  - link
  - save
  - open
  - close
  - start
  - stop
  - play
  - work
  - name
  - time
  - page
  - site
  - book
  - love
  - life
  - food
  - city
  - country

#### Lesson 8: 中級単語
- **説明**: やや長めの単語
- **出題数**: 30
- **単語リスト**（全30語）:
  - keyboard
  - computer
  - program
  - software
  - hardware
  - network
  - internet
  - database
  - function
  - variable
  - method
  - object
  - string
  - number
  - boolean
  - array
  - controller
  - service
  - component
  - interface
  - message
  - session
  - request
  - response
  - parameter
  - argument
  - document
  - element
  - attribute
  - property

#### Lesson 9: 上級単語
- **説明**: 長くて複雑な単語
- **出題数**: 30
- **単語リスト**（全30語）:
  - authentication
  - authorization
  - implementation
  - configuration
  - optimization
  - serialization
  - deserialization
  - initialization
  - synchronization
  - polymorphism
  - encapsulation
  - inheritance
  - abstraction
  - dependency
  - middleware
  - asynchronous
  - refactoring
  - architecture
  - infrastructure
  - deployment
  - scalability
  - availability
  - reliability
  - maintainability
  - compatibility
  - functionality
  - performance
  - repository
  - documentation
  - specification

---

#### カテゴリー2-2: テーマ別（Category: テーマ別）

**カテゴリー設定:**
- `requires_login: true`
- `premium: false`
- `published: true`

#### Lesson 12: 果物

**カテゴリー設定:**
- `requires_login: true`
- `premium: false`
- `published: true`

#### Lesson 10: Ruby用語
- **説明**: Ruby言語の用語
- **出題数**: 25
- **単語リスト**（全25語）:
  - ruby
  - rails
  - model
  - controller
  - view
  - gem
  - bundle
  - rake
  - migration
  - schema
  - module
  - class
  - method
  - attr
  - def
  - end
  - unless
  - yield
  - block
  - proc
  - lambda
  - scope
  - validate
  - callback
  - association

#### Lesson 11: Web用語
- **説明**: Web開発の用語
- **出題数**: 25
- **単語リスト**（全25語）:
  - html
  - css
  - javascript
  - frontend
  - backend
  - api
  - rest
  - json
  - ajax
  - fetch
  - promise
  - async
  - await
  - dom
  - event
  - listener
  - handler
  - router
  - route
  - path
  - query
  - params
  - header
  - cookie
  - session

---

### 5. テーマ別（Category: テーマ別）

**カテゴリー設定:**
- `requires_login: true`
- `premium: false`
- `published: true`

#### Lesson 12: 果物
- **説明**: 果物の名前
- **出題数**: 20
- **単語リスト**（全20語）:
  - apple
  - banana
  - orange
  - grape
  - lemon
  - peach
  - melon
  - cherry
  - strawberry
  - blueberry
  - raspberry
  - pineapple
  - watermelon
  - kiwi
  - mango
  - papaya
  - coconut
  - avocado
  - pomegranate
  - tangerine

#### Lesson 13: 天気
- **説明**: 天気に関する単語
- **出題数**: 20
- **単語リスト**（全20語）:
  - sunny
  - cloudy
  - rainy
  - snowy
  - windy
  - foggy
  - storm
  - thunder
  - lightning
  - rainbow
  - temperature
  - humidity
  - forecast
  - climate
  - season
  - spring
  - summer
  - autumn
  - winter
  - weather

#### Lesson 14: ありがちな人名
- **説明**: 英語圏の一般的な名前
- **出題数**: 20
- **単語リスト**（全20語）:
  - james
  - john
  - robert
  - michael
  - william
  - david
  - richard
  - joseph
  - thomas
  - charles
  - mary
  - patricia
  - jennifer
  - linda
  - barbara
  - elizabeth
  - susan
  - jessica
  - sarah
  - karen

---

### 6. 短文練習（Category: 短文練習）

**カテゴリー設定:**
- `requires_login: true`
- `premium: false`
- `published: true`

#### Lesson 15: 3-5語の短文
- **説明**: よく使うフレーズ
- **出題数**: 15
- **文章リスト**（全15文）:
  - hello world
  - good morning
  - thank you
  - see you later
  - how are you
  - nice to meet you
  - have a nice day
  - what is your name
  - i love ruby
  - ruby on rails
  - let me know
  - as soon as possible
  - by the way
  - for your information
  - in my opinion

#### Lesson 16: プログラミングフレーズ
- **説明**: コードでよく使う表現
- **出題数**: 15
- **文章リスト**（全15文）:
  - def method name
  - class user model
  - if condition true
  - return false unless
  - render json data
  - redirect to root
  - find by id
  - where name like
  - order by created
  - limit ten offset
  - validates presence of
  - has many comments
  - belongs to user
  - before action authenticate
  - after commit send email

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

## 🔄 移行履歴

- **Day 21**: `config/typing_lessons.yml` → PostgreSQL（Category・Lessonモデル）に移行完了
- **Day 22**: `config/typing_lessons.yml` → `CLAUDE_LESSONS.md` に移行、YAMLファイル削除予定
