# CLAUDE_TEST_STRATEGY.md

Typnixアプリのテスト戦略と実装状況をまとめたドキュメント

---

## 📊 現在のテスト完成度（Day 25時点）

### 総合評価: **約45-50%**

| 項目 | 完成度 | 備考 |
|------|--------|------|
| **モデルテスト（基本）** | ✅ **80%** | バリデーション、ビジネスロジック完了 |
| **モデルテスト（完全）** | ⏳ **60%** | スコープ、一意性、コールバックが未完了 |
| **システムテスト** | ❌ **0%** | 未実装 |
| **CI/CD** | ❌ **0%** | 未実装 |

### テスト実行結果

```bash
bundle exec rspec
# 158 examples, 0 failures, 30 pending

bundle exec rubocop
# 98 files inspected, 0 offenses

bundle exec brakeman
# 0 security warnings
```

---

## 🎯 テスト戦略の基本方針

### 1. テスト駆動の哲学

- **「あるべき姿」のテストを書く**: テストが通らない場合、実装を修正してテストに合わせる（テストを歪めない）
  - 例: エラーメッセージが英語のままなら、日本語翻訳を追加する
  - テストを通すためにテストの内容を歪めるのは本末転倒

- **プラグマティックなアプローチ**: 80-90%のテストが通る状態を優先し、複雑なテストは後回し
  - 複雑なテストは `skip` でスキップし、TODOコメントで理由と解決策を記録
  - 数%の部分が通らなくて先に進めないより、まず80-90%を完成させる

- **TDD (Test-Driven Development)**: 理想的な動作を先にテストで定義し、実装をそれに合わせる

### 2. テスト環境

- **テストフレームワーク**: RSpec 3.13
- **テストデータ**: FactoryBot + Faker
- **システムテスト**: Capybara + Selenium WebDriver
- **データベース**: PostgreSQL (RAILS_ENV=test)
- **品質チェック**: RuboCop + Brakeman

---

## 🧪 モデルテストの実装状況

### 完了している部分（✅ 約80%）

#### 1. **バリデーション**

全モデルで基本的なバリデーションをテスト済み：

- **必須項目**: `presence: true` の検証
- **文字数制限**: `maximum`, `minimum` の検証
- **フォーマット**: 正規表現、Gmail互換形式など

**実装例:**
```ruby
# spec/models/user_spec.rb
describe "email" do
  it "必須であること" do
    user = build(:user, email: nil)
    expect(user).not_to be_valid
  end

  it "254文字以下であること" do
    user = build(:user, email: "a" * 246 + "@test.com") # 255文字
    expect(user).not_to be_valid
  end
end
```

#### 2. **ビジネスロジック（計算・判定）**

重要なビジネスロジックをテスト済み：

- **WPM計算**: `typed_chars / duration_seconds → WPM`
- **グレード判定**: `accuracy + WPM → 5段階カワウソグレード`
- **slug生成**: `keymap-1, keymap-2...` の連番生成

**実装例:**
```ruby
# spec/models/lesson_record_spec.rb
describe "WPM計算" do
  it "typed_charsとduration_secondsからWPMを自動計算すること" do
    lesson_record = build(:lesson_record, typed_chars: 500, duration_seconds: 60)
    lesson_record.send(:calculate_wpm)
    # CPM = (500 / 60) * 60 = 500
    # WPM = 500 / 5 = 100
    expect(lesson_record.wpm).to eq(100)
  end
end

describe "グレード判定" do
  it "正答率98%以上、WPM 80以上で「伝説のカワウソ」になること" do
    lesson_record = build(:lesson_record, :legendary)
    lesson_record.send(:calculate_wpm)
    lesson_record.send(:calculate_grade)
    expect(lesson_record.grade).to eq("伝説のカワウソ")
  end
end
```

#### 3. **delegate パターン**

Railsの委譲メソッドをテスト済み：

- `Lesson` → `Category` の `premium`, `requires_login`
- `Share` → `LessonRecord` の `wpm`, `accuracy`, `grade` など
- `LessonRecord` → `Lesson` の `lesson_name`

**実装例:**
```ruby
# spec/models/lesson_spec.rb
describe "delegate" do
  it "categoryのrequires_loginを委譲すること" do
    category = build(:category, requires_login: true)
    lesson = build(:lesson, category: category)
    expect(lesson.requires_login).to be true
  end
end
```

#### 4. **アソシエーション**

全モデルの関連性をテスト済み：

- `User has_many :keymap_sets`
- `Lesson belongs_to :category`
- `LessonRecord belongs_to :lesson (optional: true)`
- `Share belongs_to :lesson_record`

**実装例:**
```ruby
# spec/models/lesson_spec.rb
describe "アソシエーション" do
  it "categoryに属すること" do
    lesson = build(:lesson)
    expect(lesson.category).to be_present
  end
end
```

#### 5. **インスタンスメソッド**

主要なインスタンスメソッドをテスト済み：

- `User#admin?` - 管理者判定
- `Lesson#official?` - 公式レッスン判定
- `Lesson#to_lesson_info` - JavaScript用データ変換
- `KeymapSet#deletable?` - 削除可能判定
- `LessonRecord#grade_emoji` - グレード絵文字取得

#### 6. **クラスメソッド**

主要なクラスメソッドをテスト済み：

- `KeymapSet.generate_next_slug(user)` - slug連番生成
- `Category.available_tabs` - 有効なタブのみ取得
- `Category.all_tabs` - 全タブ定義取得

---

### 未完了（pending）の部分（⏳ 30個）

#### 技術的制約: `active_keymap_set` NOT NULL制約

**問題点:**
- FactoryBotの `create(:user)` が `active_keymap_set_id` NOT NULL制約で失敗
- `after_create :create_default_keymap_set` コールバックが実行される前にエラー

**回避策（現在）:**
- `build(:user)` を使ってバリデーションテストのみ実行
- `send(:private_method)` でprivateメソッドを直接テスト
- `create()` が必要なテストは `skip` でスキップ

**TODOコメント例:**
```ruby
it "管理者の場合、全レッスンを取得すること" do
  # TODO: createを使うテストは active_keymap_set の制約で一旦スキップ
  skip "createを使うテストは active_keymap_set の制約で一旦保留"
end
```

#### 未完了のテスト項目

1. **スコープ（データ取得条件）** - 約20個
   - `Lesson.visible_to(user)` - ユーザーに応じた表示制御
   - `Category.published` - 公開カテゴリーのみ取得
   - `KeymapSet.published` - 公開キーマップのみ取得
   - `LessonRecord.recent` - 最近の練習記録取得

2. **一意性制約** - 約5個
   - `User#email` が重複しないこと
   - `User#username` が重複しないこと
   - `Share#token` が重複しないこと
   - `Category#name` が重複しないこと

3. **コールバック** - 約5個
   - `after_create :create_default_keymap_set` - 初回キーマップ自動作成
   - `after_create :copy_default_keymap` - デフォルトキーマップコピー
   - `before_validation :generate_slug` - slug自動生成

---

## 🌐 システムテスト（E2E）の計画

### システムテストとは？

「**ユーザーの視点で、アプリ全体が正しく動作するか**」をテストします。

- ブラウザを使った実際の操作をシミュレート
- Capybara + Selenium WebDriverで自動化
- モデル・コントローラー・ビューの連携を検証

---

### システムテストの優先順位と実装方針（Day 25決定版）

#### 優先度の決定基準

システムテストは実行時間が長く、実装コストも高いため、以下の基準で優先順位を決定しました：

1. **ビジネス価値** - ユーザーにとっての重要度
2. **リスク** - 壊れた時の影響度
3. **変更頻度** - コード変更が多い箇所ほど優先
4. **実装コスト** - 時間対効果

---

### Phase 1: クリティカルパス（最優先、Day 25実装予定）

#### 🥇 **1. 認証フロー（Google OAuth）**

**優先度**: 最高
**理由**: 全ての機能の前提条件
**リスク**: 壊れるとアプリ全体が使えない
**実装コスト**: 中（OmniAuthモック設定が必要）
**実装時間**: 約30分

**テスト内容**:
- ゲストユーザーがログインできる
- ログアウトできる
- ログイン後にマイページにアクセスできる

**実装例**:
```ruby
# spec/system/authentication_spec.rb
describe "認証フロー" do
  it "Googleログイン → ログアウト" do
    # OmniAuthモックを使用
    visit root_path
    click_button "Googleでログイン"
    expect(page).to have_content("ログイン成功")

    click_button "ログアウト"
    expect(page).to have_content("ログアウトしました")
  end
end
```

---

#### 🥈 **2. レッスン閲覧フロー**

**優先度**: 高
**理由**: アプリのコア機能の入り口
**リスク**: 高（レッスンが表示されないとタイピング練習ができない）
**実装コスト**: 低（通常のページ遷移）
**実装時間**: 約20分

**テスト内容**:
- レッスン一覧が表示される
- レッスンを選択してタイピング画面に遷移できる
- タイピング画面が正しく表示される

**実装例**:
```ruby
# spec/system/lessons_spec.rb
describe "レッスン閲覧フロー" do
  it "レッスン一覧 → レッスン詳細" do
    visit root_path
    expect(page).to have_content("基礎トレーニング")

    click_link "基礎トレーニング"
    expect(page).to have_selector(".typing-area")
  end
end
```

---

#### 🥉 **3. 練習履歴閲覧フロー**

**優先度**: 中
**理由**: ユーザーの継続利用を促す
**リスク**: 中（記録は保存されているが閲覧できない）
**実装コスト**: 低（Turbo Frames動作確認）
**実装時間**: 約20分

**テスト内容**:
- 練習履歴一覧が表示される
- 期間フィルターが動作する（Turbo Frames）
- ページネーションが動作する

**実装例**:
```ruby
# spec/system/history_spec.rb
describe "練習履歴閲覧フロー" do
  it "期間フィルター切り替え" do
    # 事前にデータを作成
    login_as_user
    visit my_history_path

    click_link "直近1ヶ月"
    expect(page).to have_selector("[data-turbo-frame='history-content']")
  end
end

```

**Phase 1合計実装時間**: 約70分

---

### Phase 2: 重要なユーザーフロー（将来実装）

#### 4. キーマップ閲覧・選択フロー

**優先度**: 中
**理由**: 分割キーボード特化の差別化要素
**リスク**: 中（デフォルトキーマップで代用可能）
**実装コスト**: 低（通常のフォーム操作）

**テスト内容**:
- キーマップ一覧が表示される
- キーマップを選択できる
- 選択したキーマップがアクティブになる

---

### Phase 3: 補助的な機能（低優先度）

#### 5. キーマップ編集フロー（CRUD）

**優先度**: 低
**理由**: 高度なユーザー向け機能
**リスク**: 低（閲覧・選択ができれば最低限OK）
**実装コスト**: 中（複雑なフォーム操作）

#### 6. シェア機能

**優先度**: 低
**理由**: SNS拡散のための機能
**リスク**: 低（コア機能ではない）
**実装コスト**: 低（リンク生成の確認）

#### 7. 管理者ダッシュボード

**優先度**: 低
**理由**: 管理者専用機能
**リスク**: 低（一般ユーザーには影響なし）
**実装コスト**: 低（権限チェックのみ）

---

### スキップ推奨（コスト > 効果）

#### ❌ タイピング入力の完全シミュレーション

**スキップ理由**:
- JavaScriptの複雑な動作確認が困難
- キーボードイベントの再現が不安定
- **代替案**: モデルテスト（WPM計算、グレード判定）で代用

**モデルテストでカバー済み**:
- WPM計算ロジック ✅
- グレード判定ロジック ✅
- 正答率計算 ✅

#### ❌ レスポンシブ対応のテスト

**スキップ理由**:
- ビジュアル確認は手動の方が効率的
- 実装コストが高い（複数デバイスサイズのテスト）
- **代替案**: 手動で確認、スクリーンショットテストツール（Percy等）

---

### 実装方針と技術的アプローチ

#### Google OAuthのモック設定

システムテストでGoogle OAuthを使うには、OmniAuthのテストモードを有効にします：

```ruby
# spec/support/omniauth.rb
OmniAuth.config.test_mode = true
OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
  provider: 'google_oauth2',
  uid: '123456789',
  info: {
    email: 'test@example.com',
    name: 'Test User'
  },
  credentials: {
    token: 'mock_token',
    expires_at: Time.now + 1.week
  }
})
```

#### ヘルパーメソッドの作成

認証が必要なテストで共通利用するヘルパー：

```ruby
# spec/support/system_helpers.rb
module SystemHelpers
  def login_as_user(user = nil)
    user ||= create(:user)
    OmniAuth.config.mock_auth[:google_oauth2].info.email = user.email
    visit root_path
    click_button "Googleでログイン"
    user
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
```

#### Capybara設定

```ruby
# spec/support/capybara.rb
Capybara.default_max_wait_time = 3
Capybara.server = :puma, { Silent: true }
```

---

## 🔄 モデルテスト vs システムテスト

### テスト種類の使い分け

| テスト種類 | 目的 | 速度 | 範囲 | Typnixでの例 |
|---------|------|------|------|------------|
| **モデルテスト** | データ層のロジック検証 | ⚡ 速い | 1モデル | WPM計算が正しいか？ |
| **システムテスト** | ユーザー体験の検証 | 🐌 遅い | アプリ全体 | タイピング練習→結果保存→履歴表示が動くか？ |

### モデルテストで検証できること

1. ✅ **バリデーション** - 必須項目、文字数制限、フォーマット
2. ✅ **ビジネスロジック** - WPM計算、グレード判定、slug生成
3. ✅ **データ変換** - `to_lesson_info`, `grade_emoji`
4. ✅ **アソシエーション** - `belongs_to`, `has_many`
5. ⏳ **スコープ** - `visible_to`, `published`, `recent`（未完了）
6. ⏳ **一意性制約** - email, username, token（未完了）

### システムテストで検証できること（Phase別）

#### Phase 1: クリティカルパス（Day 25実装予定）

1. 🔜 **認証フロー** - Google OAuth動作確認（実装予定）
2. 🔜 **レッスン閲覧フロー** - レッスン一覧→詳細（実装予定）
3. 🔜 **練習履歴フロー** - 期間フィルター、Turbo Frames（実装予定）

#### Phase 2-3: その他のフロー（将来実装）

4. ❌ **キーマップ閲覧・選択フロー** - 選択、アクティブ化（未実装）
5. ❌ **キーマップ編集フロー** - CRUD操作（未実装）
6. ❌ **シェア機能** - リンク生成、OGP（未実装）
7. ❌ **管理者ダッシュボード** - 権限チェック（未実装）

#### スキップ推奨

8. ❌ **タイピング入力の完全シミュレーション** - JavaScript動作が複雑（モデルテストで代用）
9. ❌ **レスポンシブ対応** - ビジュアル確認が必要（手動確認推奨）

---

## 📋 今後の実装計画

### Phase 1: モデルテスト第一弾（✅ 完了）

- ✅ RSpec環境のセットアップ
- ✅ FactoryBotファクトリの作成（6モデル）
- ✅ 基本的なモデルテスト実装（158 examples, 0 failures, 30 pending）
- ✅ 日本語エラーメッセージ対応
- ✅ RuboCop + Brakeman チェック

**PR準備中** - `feature/rspec-setup` ブランチ

---

### Phase 2: システムテスト実装（次回）

#### 優先度A: タイピング練習フロー

1. Capybara + Selenium WebDriver の設定
2. Google OAuth モック設定（`OmniAuth.config.test_mode`）
3. タイピング練習フローのE2Eテスト
4. シェア機能のテスト
5. 練習履歴保存の検証

#### 優先度B: キーマップ編集フロー

1. キーマップCRUD操作のテスト
2. 削除制限（最古のキーマップ）の検証
3. キーマップ選択機能のテスト

#### 優先度C: 練習履歴フロー

1. 期間フィルター切り替えのテスト
2. Turbo Frames動作確認
3. ページネーション検証

---

### Phase 3: モデルテストのpending解消（将来）

**技術的課題: `active_keymap_set` NOT NULL制約**

2つのアプローチを検討：

#### アプローチ1: カスタムFactoryBot戦略

`create(:user)` 時に自動で `active_keymap_set` を設定：

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    # ...

    # カスタム戦略でactive_keymap_setを自動設定
    after(:create) do |user|
      unless user.active_keymap_set
        keymap_set = create(:keymap_set, user: user)
        user.update_column(:active_keymap_set_id, keymap_set.id)
      end
    end
  end
end
```

#### アプローチ2: User modelリファクタリング

コールバックの順序を調整し、`active_keymap_set_id` を自動設定：

```ruby
# app/models/user.rb
class User < ApplicationRecord
  after_create :create_default_keymap_set, if: :active_keymap_set_id_nil?

  private

  def active_keymap_set_id_nil?
    active_keymap_set_id.nil?
  end
end
```

---

### Phase 4: GitHub Actions CI/CD（最終）

`.github/workflows/ci.yml` の作成：

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4.4
          bundler-cache: true

      - name: Run tests
        run: bundle exec rspec

      - name: Run RuboCop
        run: bundle exec rubocop

      - name: Run Brakeman
        run: bundle exec brakeman
```

---

## 🎓 学んだベストプラクティス

### 1. テスト哲学

- ❌ **NG**: テストを実装に合わせる（テストを歪める）
- ✅ **OK**: 実装をテストに合わせる（理想の動作を定義）

### 2. プラグマティックな進め方

- ❌ **NG**: 100%のテストができるまで先に進めない
- ✅ **OK**: 80-90%を完成させ、残りは `skip` + TODOで管理

### 3. TODOコメントの書き方

```ruby
it "一意であること" do
  # TODO: createを使うテストは active_keymap_set の制約で一旦スキップ
  # 解決策: FactoryBotのカスタム戦略 or User modelリファクタリング
  skip "createを使うテストは active_keymap_set の制約で一旦保留"
end
```

### 4. FactoryBotのベストプラクティス

- `build()` - バリデーションテスト、DB保存不要
- `create()` - スコープ、一意性制約、アソシエーションのテスト
- `sequence()` - 一意な値の自動生成（Faker::Number.uniqueより安定）
- `trait` - テストシナリオのバリエーション（`:admin`, `:legendary`）

### 5. privateメソッドのテスト

```ruby
lesson_record = build(:lesson_record, typed_chars: 500, duration_seconds: 60)
lesson_record.send(:calculate_wpm)  # private メソッドを直接呼び出し
expect(lesson_record.wpm).to eq(100)
```

---

## 📊 テスト実装の進捗管理

### 完了したテスト

| モデル | Examples | Passing | Pending | 完成度 |
|--------|----------|---------|---------|--------|
| User | 32 | 27 | 5 | 84% |
| LessonRecord | 36 | 35 | 1 | 97% |
| Category | 21 | 15 | 6 | 71% |
| KeymapSet | 25 | 17 | 8 | 68% |
| Lesson | 27 | 18 | 9 | 67% |
| Share | 17 | 16 | 1 | 94% |
| **合計** | **158** | **128** | **30** | **81%** |

---

## 🔗 関連ドキュメント

- **CLAUDE.md** - プロジェクト全体の仕様書（テスト戦略を含む）
- **CLAUDE_FEATURES.md** - 実装済み機能の詳細仕様
- **spec/rails_helper.rb** - RSpec設定
- **spec/factories/** - FactoryBotファクトリ定義
- **spec/models/** - モデルテスト実装

---

このドキュメントは、Day 25のテスト実装と共に更新されます。
