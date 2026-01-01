# RSpecによるテスト戦略

**難易度**: 🔴 上級
**推定学習時間**: 2.5〜3時間
**対応する日報**: Day 25, Day 26, Day 27
**関連PR**: #84, #85, #93

---

## 🎯 学習目標

この教材を学ぶことで、以下ができるようになります：

- RSpec環境を構築し、FactoryBotでテストデータを作成できる
- モデルテストでビジネスロジックを検証できる
- システムテスト（E2E）でユーザー体験を保証できる
- 「あるべき姿」のテスト哲学を理解し、プラグマティックに実装できる
- テストの優先順位を判断し、効率的にテストカバレッジを向上できる

---

## 📚 前提知識

この教材を理解するには、以下の知識が必要です：

- Railsの基本的なテスティング概念（単体テスト、統合テスト）
- RSpecの基本文法（describe, context, it, expect）
- FactoryBotの基本的な使い方（build, create）
- Capybaraの基本的なAPI（visit, click_button, fill_in）

---

## 📖 本編

### 概要

Day 1から24まで、Typnixプロジェクトは「動くコードを書く」ことに集中してきました。機能追加、バグ修正、リファクタリングを繰り返し、本番環境で動作するアプリケーションを構築しました。

しかし、テストがない状態での開発には大きなリスクがあります：

- **回帰バグ**: 新機能を追加すると、既存機能が壊れる
- **リファクタリングの恐怖**: コードを改善したいが、壊れるかもしれない不安
- **仕様の曖昧さ**: 実装者の記憶に依存し、他の開発者が理解しづらい

Day 25-27では、このリスクを解消するため、**RSpecによる包括的なテスト環境**を構築しました。

---

### 実装前（アンチパターン / 課題）

#### アンチパターン1: テストなしの開発

Day 24までのTypnixプロジェクトは、以下の状態でした：

```ruby
# テストファイルがない状態
spec/
# 空っぽ
```

**問題点:**
- 新機能追加時に既存機能が壊れていないか手動で確認
- リファクタリングが怖くて、コードが徐々に複雑化
- バグ修正後に同じバグが再発する可能性
- 他の開発者がコードの意図を理解しづらい

#### アンチパターン2: 100%カバレッジ強迫観念

テストを導入する際、以下のような「完璧主義」に陥ることがあります：

```ruby
# 全てのケースを網羅しようとする
describe "username" do
  it "1文字は無効" do
    expect(build(:user, username: "a")).not_to be_valid
  end

  it "2文字は無効" do
    expect(build(:user, username: "ab")).not_to be_valid
  end

  it "3文字は有効" do
    expect(build(:user, username: "abc")).to be_valid
  end

  # 30文字まで全てテスト...（膨大な数のテストケース）
end
```

**問題点:**
- テストの作成に時間がかかりすぎる
- テストケースが多すぎて、重要なテストが埋もれる
- メンテナンスコストが高い
- 完璧を目指して先に進めなくなる

#### アンチパターン3: テストを歪める

実装がテストに合わない場合、テストを歪めてしまうことがあります：

```ruby
# 実装: エラーメッセージが英語のまま
it "必須であること" do
  user = build(:user, email: nil)
  expect(user).not_to be_valid
  # 本来は「を入力してください」と日本語で表示すべきだが...
  expect(user.errors[:email]).to include("can't be blank")  # 英語で妥協
end
```

**問題点:**
- テストが「あるべき姿」ではなく「現状」を追認してしまう
- ユーザー体験が損なわれる（英語エラーメッセージ）
- テストの意味がなくなる（仕様書としての役割を失う）

---

### 実装後（ベストプラクティス）

#### 1. RSpec環境構築（Day 25）

**Gemfile:**
```ruby
group :development, :test do
  gem "rspec-rails"        # RSpecのRails統合
  gem "factory_bot_rails"  # テストデータ作成
  gem "faker"              # ダミーデータ生成
end

group :test do
  gem "capybara"           # システムテスト（ブラウザ操作）
  gem "selenium-webdriver" # ブラウザドライバ
end
```

**rails_helper.rb:**
```ruby
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

# FactoryBot設定
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods  # build, create をそのまま使える
  config.fixture_path = Rails.root.join('spec/fixtures')
  config.use_transactional_fixtures = true  # 各テスト後にDBロールバック
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
```

**ディレクトリ構成:**
```
spec/
├── factories/           # FactoryBotのファクトリ定義
│   ├── users.rb
│   ├── lesson_records.rb
│   ├── lessons.rb
│   ├── categories.rb
│   ├── keymap_sets.rb
│   └── shares.rb
├── models/              # モデルテスト
│   ├── user_spec.rb
│   ├── lesson_record_spec.rb
│   ├── lesson_spec.rb
│   ├── category_spec.rb
│   ├── keymap_set_spec.rb
│   └── share_spec.rb
├── system/              # システムテスト（E2E）
│   ├── authentication_spec.rb
│   ├── lessons_spec.rb
│   ├── history_spec.rb
│   └── typing_highlight_spec.rb
├── support/             # テストヘルパー、共通設定
│   ├── capybara.rb
│   ├── google_id_token_mock.rb
│   └── system_helpers.rb
├── rails_helper.rb      # Rails用RSpec設定
└── spec_helper.rb       # RSpec基本設定
```

**改善点:**
- アルファベット順に並べて、gemの依存関係を明確化
- `use_transactional_fixtures` で各テスト後に自動ロールバック
- FactoryBotのメソッドをグローバルに使える（`FactoryBot.create` → `create`）

#### 2. モデルテスト（Day 25）

**spec/models/lesson_record_spec.rb:**
```ruby
require "rails_helper"

RSpec.describe LessonRecord, type: :model do
  describe "バリデーション" do
    it "有効なファクトリを持つこと" do
      lesson_record = build(:lesson_record)
      expect(lesson_record).to be_valid
    end

    describe "accuracy" do
      it "0以上100以下であること" do
        expect(build(:lesson_record, accuracy: -0.1)).not_to be_valid
        expect(build(:lesson_record, accuracy: 0)).to be_valid
        expect(build(:lesson_record, accuracy: 50.5)).to be_valid
        expect(build(:lesson_record, accuracy: 100)).to be_valid
        expect(build(:lesson_record, accuracy: 100.1)).not_to be_valid
      end

      it "nilを許容すること" do
        expect(build(:lesson_record, accuracy: nil)).to be_valid
      end
    end
  end

  describe "WPM計算" do
    it "typed_charsとduration_secondsからWPMを自動計算すること" do
      lesson_record = build(:lesson_record, typed_chars: 500, duration_seconds: 60)
      lesson_record.send(:calculate_wpm)  # private メソッドを直接呼び出し
      # CPM = (500 / 60) * 60 = 500
      # WPM = 500 / 5 = 100
      expect(lesson_record.wpm).to eq(100)
    end

    it "duration_secondsが0の場合、WPMを計算しないこと" do
      lesson_record = build(:lesson_record, typed_chars: 500, duration_seconds: 0)
      lesson_record.send(:calculate_wpm)
      expect(lesson_record.wpm).to be_nil
    end

    it "小数点以下を四捨五入すること" do
      lesson_record = build(:lesson_record, typed_chars: 333, duration_seconds: 60)
      lesson_record.send(:calculate_wpm)
      # CPM = (333 / 60) * 60 = 333
      # WPM = 333 / 5 = 66.6 → 67（四捨五入）
      expect(lesson_record.wpm).to eq(67)
    end
  end

  describe "グレード判定" do
    context "伝説のカワウソ級" do
      it "正答率98%以上、WPM 80以上で「伝説のカワウソ」になること" do
        lesson_record = build(:lesson_record, :legendary)
        lesson_record.send(:calculate_wpm)
        lesson_record.send(:calculate_grade)
        expect(lesson_record.grade).to eq("伝説のカワウソ")
      end

      it "正答率98%、WPM 80で「伝説のカワウソ」になること（境界値）" do
        lesson_record = build(:lesson_record, accuracy: 98.0, typed_chars: 800, duration_seconds: 120)
        lesson_record.send(:calculate_wpm)
        lesson_record.send(:calculate_grade)
        expect(lesson_record.grade).to eq("伝説のカワウソ")
      end
    end

    context "熟練のカワウソ級" do
      it "正答率90%以上、WPM 50以上で「熟練のカワウソ」になること" do
        lesson_record = build(:lesson_record, :adult)
        lesson_record.send(:calculate_wpm)
        lesson_record.send(:calculate_grade)
        expect(lesson_record.grade).to eq("熟練のカワウソ")
      end

      it "正答率97%でもWPM 49なら「熟練のカワウソ」にならないこと" do
        lesson_record = build(:lesson_record, accuracy: 97.0, typed_chars: 490, duration_seconds: 120)
        lesson_record.send(:calculate_wpm)
        lesson_record.send(:calculate_grade)
        expect(lesson_record.grade).to eq("若手のカワウソ")
      end
    end
  end
end
```

**FactoryBot（spec/factories/lesson_records.rb）:**
```ruby
FactoryBot.define do
  factory :lesson_record do
    association :user
    association :lesson

    word_count { 10 }
    correct_count { 8 }
    mistake_count { 2 }
    accuracy { 80.0 }
    typed_chars { 50 }
    duration_seconds { 30 }
    completed_at { Time.current }

    trait :legendary do
      accuracy { 99.0 }
      typed_chars { 800 }
      duration_seconds { 60 }
    end

    trait :adult do
      accuracy { 95.0 }
      typed_chars { 600 }
      duration_seconds { 60 }
    end

    trait :young do
      accuracy { 85.0 }
      typed_chars { 400 }
      duration_seconds { 60 }
    end

    trait :child do
      accuracy { 75.0 }
      typed_chars { 200 }
      duration_seconds { 60 }
    end

    trait :baby do
      accuracy { 60.0 }
      typed_chars { 100 }
      duration_seconds { 60 }
    end
  end
end
```

**改善点:**
- `build()` を使ってDB保存なしでバリデーションテスト
- `send(:private_method)` でprivateメソッドを直接テスト
- `trait` で多様なシナリオを表現（伝説級、熟練級など）
- 境界値テストで境界条件を明確化

**テスト実行結果（Day 25）:**
```bash
bundle exec rspec spec/models/
# 158 examples, 0 failures, 30 pending
# 実行時間: 0.35秒
```

| モデル | Examples | Passing | Pending | 完成度 |
|--------|----------|---------|---------|--------|
| User | 32 | 27 | 5 | 84% |
| LessonRecord | 36 | 35 | 1 | 97% |
| Category | 21 | 15 | 6 | 71% |
| KeymapSet | 25 | 17 | 8 | 68% |
| Lesson | 27 | 18 | 9 | 67% |
| Share | 17 | 16 | 1 | 94% |
| **合計** | **158** | **128** | **30** | **81%** |

#### 3. システムテスト（E2E）（Day 25, Day 27）

**spec/system/authentication_spec.rb:**
```ruby
require "rails_helper"

RSpec.describe "認証フロー", type: :system do
  describe "ログイン状態の確認" do
    it "ログインユーザーのユーザー名が表示される" do
      user = login_as_user
      visit root_path

      # ログイン後はユーザー名が表示される（ユーザーメニュー内）
      expect(page).to have_content(user.name)
    end

    it "未ログインユーザーにはログインエリアが表示される" do
      visit root_path

      # ログイン前はGoogle Sign-In要素が表示される
      expect(page).to have_selector(".g_id_signin")
    end
  end

  describe "ログアウト" do
    it "ログインユーザーがログアウトできる" do
      login_as_user
      visit root_path

      # ユーザーメニューを開く
      find("button[data-action='click->user-menu#toggle']").click

      # ログアウトボタンをクリック
      click_button "ログアウト"

      # ログアウト後はGoogle Sign-In要素が表示される
      expect(page).to have_selector(".g_id_signin")
    end
  end
end
```

**spec/system/typing_highlight_spec.rb（Day 27）:**
```ruby
require "rails_helper"

RSpec.describe "タイピング練習のキーハイライト", type: :system do
  let(:user) { create(:user) }
  let(:category) { create(:category, tab: "basics", published: true) }
  let(:lesson) { create(:lesson, category: category, items: [ "hello", "world" ], count: 2) }
  let(:keymap_set) { create(:keymap_set, user: user, name: "テスト用キーマップ") }

  before do
    # "hello"と"world"を打つための最小限のキーマップを作成
    keymap_set.keymaps.find_by(layer: 0, key_position: "L2-R0").update(character: "h")
    keymap_set.keymaps.find_by(layer: 0, key_position: "L0-R2").update(character: "e")
    keymap_set.keymaps.find_by(layer: 0, key_position: "L2-R3").update(character: "l")
    keymap_set.keymaps.find_by(layer: 0, key_position: "R2-R2").update(character: "o")
    keymap_set.keymaps.find_by(layer: 0, key_position: "L1-R1").update(character: "w")
    keymap_set.keymaps.find_by(layer: 0, key_position: "L1-R4").update(character: "r")
    keymap_set.keymaps.find_by(layer: 0, key_position: "L2-R2").update(character: "d")

    user.update(active_keymap_set: keymap_set)
  end

  describe "初期表示時のキーハイライト", js: true do
    it "最初の文字に対応するキーが正しくハイライトされる" do
      login_as_user(user)
      visit lesson_path(lesson)

      # レッスン画面が表示されることを確認
      expect(page).to have_selector("[data-typing-target='lessonScreen']", visible: true)

      # 最初の単語の最初の文字がハイライトされる
      expect(
        page.has_selector?('.key.ring-2[data-position="L2-R0"]') || # h
        page.has_selector?('.key.ring-2[data-position="L1-R1"]')    # w
      ).to be true
    end

    it "対応する指ガイドもハイライトされる" do
      login_as_user(user)
      visit lesson_path(lesson)

      # 指ガイドがハイライトされることを確認
      expect(
        page.has_selector?('.finger-guide.ring-2[data-finger="left-middle"]') || # h
        page.has_selector?('.finger-guide.ring-2[data-finger="left-pinky"]')    # w
      ).to be true
    end
  end

  describe "文字入力後のハイライト変化", js: true do
    let(:lesson) { create(:lesson, category: category, items: [ "hello" ], count: 1) }

    it "正しい文字を入力すると次のキーがハイライトされる" do
      login_as_user(user)
      visit lesson_path(lesson)

      # 最初は"h"（L2-R0）がハイライトされる
      expect(page).to have_selector('.key.ring-2[data-position="L2-R0"]')

      # "h"を入力
      input_field = page.find('[data-typing-target="input"]', visible: :all)
      input_field.send_keys("h")

      # 少し待機（Stimulus Controllerの処理を待つ）
      sleep 0.1

      # 次の文字"e"（L0-R2）がハイライトされる
      expect(page).to have_selector('.key.ring-2[data-position="L0-R2"]')
      expect(page).to have_selector('.finger-guide.ring-2[data-finger="left-ring"]')
    end

    it "間違った文字を入力すると現在の文字が赤くハイライトされる" do
      login_as_user(user)
      visit lesson_path(lesson)

      # 間違った文字"x"を入力
      input_field = page.find('[data-typing-target="input"]', visible: :all)
      input_field.send_keys("x")

      sleep 0.1

      # 現在の文字が赤くハイライトされる
      display_area = page.find('[data-typing-target="display"]')
      expect(display_area).to have_selector('span.bg-red-100')
    end
  end

  describe "タイピング完了", js: true do
    let(:lesson) { create(:lesson, category: category, items: [ "he" ], count: 1) }

    it "全ての文字を入力すると完了画面が表示される" do
      login_as_user(user)
      visit lesson_path(lesson)

      # "h"と"e"を入力
      input_field = page.find('[data-typing-target="input"]', visible: :all)
      input_field.send_keys("he")

      # 完了画面が表示されるまで待機（最大5秒）
      expect(page).to have_selector('[data-typing-target="completionScreen"]', visible: true, wait: 5)

      # 統計情報が表示される
      expect(page).to have_selector('[data-typing-target="accuracyDisplay"]')
      expect(page).to have_selector('[data-typing-target="wpmDisplay"]')
      expect(page).to have_selector('[data-typing-target="timeDisplay"]')
      expect(page).to have_selector('[data-typing-target="mistakesDisplay"]')
    end
  end
end
```

**spec/support/system_helpers.rb:**
```ruby
module SystemHelpers
  def login_as_user(user = nil)
    user ||= create(:user)

    if page.driver.is_a?(Capybara::RackTest::Driver)
      # rack_test: POSTでセッション設定（速い）
      page.driver.post "/test/sessions", user_id: user.id
    else
      # Selenium: GET経由でセッション設定（ブラウザ互換）
      visit "/test/sessions?user_id=#{user.id}"
    end

    user
  end

  def logout
    if page.driver.is_a?(Capybara::RackTest::Driver)
      page.driver.delete "/test/sessions"
    else
      visit "/test/sessions/logout"
    end
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
```

**app/controllers/test_sessions_controller.rb:**
```ruby
class TestSessionsController < ApplicationController
  # テスト環境専用のセッション管理コントローラー
  # 本番環境では404を返す
  before_action :ensure_test_environment

  def create
    user_id = params[:user_id]
    session[:user_id] = user_id
    head :ok
  end

  def show
    # Seleniumドライバー用（GET経由でセッション設定）
    user_id = params[:user_id]
    session[:user_id] = user_id
    render plain: "Logged in as user #{user_id}"
  end

  def destroy
    session[:user_id] = nil
    head :ok
  end

  private

  def ensure_test_environment
    head :not_found unless Rails.env.test?
  end
end
```

**config/routes.rb:**
```ruby
if Rails.env.test?
  post "/test/sessions", to: "test_sessions#create"
  get "/test/sessions", to: "test_sessions#show"
  delete "/test/sessions", to: "test_sessions#destroy"
end
```

**改善点:**
- Capybaraドライバーの自動判定（rack_test vs selenium_chrome_headless）
- テスト環境専用のセッション管理（本番環境では404）
- DeviseのWarden::Test::Helpersに似たアプローチ
- `js: true` でJavaScriptを有効化し、キーハイライトをテスト

**テスト実行結果（Day 27）:**
```bash
bundle exec rspec spec/system/typing_highlight_spec.rb
# 7 examples, 0 failures
# 実行時間: 10.46秒
```

#### 4. 「あるべき姿」のテスト哲学

Day 25で確立したテスト方針：

**1. テストが通らない場合、実装を修正してテストに合わせる（テストを歪めない）**

```ruby
# ❌ テストを歪める（アンチパターン）
it "必須であること" do
  user = build(:user, email: nil)
  expect(user).not_to be_valid
  # 英語エラーメッセージで妥協
  expect(user.errors[:email]).to include("can't be blank")
end

# ✅ テストに合わせて実装を修正（ベストプラクティス）
it "必須であること" do
  user = build(:user, email: nil)
  expect(user).not_to be_valid
  # 日本語エラーメッセージを期待
  expect(user.errors[:email]).to include("を入力してください")
end

# config/locales/ja.yml を追加
ja:
  activerecord:
    attributes:
      user:
        email: "メールアドレス"
    errors:
      messages:
        blank: "を入力してください"
```

**2. プラグマティックなアプローチ: 80-90%のテストが通る状態を優先**

```ruby
# 複雑なテストは skip でスキップし、TODOコメントで理由と解決策を記録
it "一意であること" do
  # TODO: createを使うテストは active_keymap_set の制約で一旦スキップ
  # 解決策: FactoryBotのカスタム戦略 or User modelリファクタリング
  skip "createを使うテストは active_keymap_set の制約で一旦保留"
end
```

**3. TDD (Test-Driven Development): 理想的な動作を先にテストで定義**

```ruby
# 先にテストを書く
it "WPMが正確に計算されること" do
  lesson_record = build(:lesson_record, typed_chars: 500, duration_seconds: 60)
  lesson_record.send(:calculate_wpm)
  expect(lesson_record.wpm).to eq(100)  # CPM 500 / 5 = WPM 100
end

# 次に実装を書く
class LessonRecord < ApplicationRecord
  before_save :calculate_wpm

  private

  def calculate_wpm
    return if typed_chars.nil? || duration_seconds.nil? || duration_seconds.zero?
    cpm = (typed_chars.to_f / duration_seconds) * 60
    self.wpm = (cpm / 5).round
  end
end
```

#### 5. プラグマティックなアプローチの実践

**問題:** `active_keymap_set_id` NOT NULL制約でテストが複雑化

Day 25時点のUserモデル:
```ruby
class User < ApplicationRecord
  belongs_to :active_keymap_set, class_name: "KeymapSet", optional: false

  after_create :create_default_keymap_set

  private

  def create_default_keymap_set
    # ユーザー作成時にデフォルトキーマップセットを作成
    keymap_set = keymap_sets.create!(name: "デフォルトキーマップ", is_public: false)
    update!(active_keymap_set: keymap_set)
  end
end
```

**問題の詳細:**
```ruby
# FactoryBotでユーザーを作成しようとすると...
user = create(:user)
# => PG::NotNullViolation: ERROR:  null value in column "active_keymap_set_id"
#    violates not-null constraint
```

Railsのトランザクション順序:
1. `INSERT`（データベースへの保存）
2. NOT NULL制約チェック ← ここでエラー発生
3. `after_create`コールバック（`active_keymap_set`を設定）

**Day 25時点の解決策: 80-90%を先に完成させる**

```ruby
# spec/models/user_spec.rb
describe "google_uid" do
  it "必須であること" do
    user = build(:user, google_uid: nil)  # build() を使う（DB保存なし）
    expect(user).not_to be_valid
    expect(user.errors[:google_uid]).to include("を入力してください")
  end

  it "一意であること" do
    # TODO: createを使うテストは active_keymap_set の制約で一旦スキップ
    # 解決策: FactoryBotのカスタム戦略 or User modelリファクタリング
    skip "createを使うテストは active_keymap_set の制約で一旦保留"
  end
end
```

**Day 25のアプローチ:**
- `build()` でバリデーションテストのみ実行
- `create()` が必要なテストは `skip` でスキップ
- TODOコメントで「なぜ」「どう解決するか」を記録

**結果:**
- 158 examples中128 examples（81%）が成功
- 30 examples（19%）がpending
- **完璧を目指して0%より、80%を先に完成させる方が建設的**

**Day 25後の解決（システムテスト実装時）:**

```ruby
# マイグレーション: NOT NULL制約を削除
class ChangeActiveKeymapSetIdToOptionalInUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :active_keymap_set_id, true
  end
end

# モデル: optional: true に変更
class User < ApplicationRecord
  belongs_to :active_keymap_set, class_name: "KeymapSet", optional: true

  after_create :create_default_keymap_set

  # カスタムバリデーション: 作成後に active_keymap_set が必須
  validate :must_have_active_keymap_set_after_creation

  private

  def must_have_active_keymap_set_after_creation
    return if new_record?  # 新規作成時はチェックしない
    return if active_keymap_set_id.present?
    errors.add(:active_keymap_set, "は必須です")
  end

  def create_default_keymap_set
    keymap_set = keymap_sets.create!(name: "デフォルトキーマップ", is_public: false)
    update!(active_keymap_set: keymap_set)
  end
end
```

**効果:**
- システムテストでユーザー作成が可能に
- モデルテストの30個のスキップも解消可能（別ブランチで対応予定）
- プラグマティックなアプローチにより、先に進むことができた

#### 6. 技術的負債の管理

**skipしたテストの例:**
```ruby
it "一意であること" do
  # TODO: createを使うテストは active_keymap_set の制約で一旦スキップ
  # 解決策: FactoryBotのカスタム戦略 or User modelリファクタリング
  skip "createを使うテストは active_keymap_set の制約で一旦保留"
end
```

**TODOコメントに含めるべき情報:**
1. **なぜスキップしたか**: `active_keymap_set` NOT NULL制約との競合
2. **どう解決するか**: FactoryBotのカスタム戦略 or User modelリファクタリング
3. **いつ解決するか**: （明記されていない場合、優先度は低い）

**技術的負債の管理方針:**
- skipしたテストは「技術的負債」として管理
- 時間のある時に1つずつ解消
- プロジェクトの進捗を止めないことを優先

---

### 解説

#### なぜこの設計が優れているのか

**1. テストが仕様書の役割を果たす**

テストコードを読めば、モデルの仕様が理解できます：

```ruby
describe "グレード判定" do
  context "伝説のカワウソ級" do
    it "正答率98%以上、WPM 80以上で「伝説のカワウソ」になること" do
      lesson_record = build(:lesson_record, :legendary)
      lesson_record.send(:calculate_wpm)
      lesson_record.send(:calculate_grade)
      expect(lesson_record.grade).to eq("伝説のカワウソ")
    end
  end
end
```

このテストを読むだけで、「正答率98%以上かつWPM 80以上で伝説のカワウソ級」という仕様が理解できます。

**2. リファクタリングの安全性向上**

テストがあることで、リファクタリング後も動作保証されます：

```ruby
# Before (リファクタリング前)
def calculate_grade
  if accuracy >= 98 && wpm >= 80
    self.grade = "伝説のカワウソ"
  elsif accuracy >= 90 && wpm >= 50
    self.grade = "熟練のカワウソ"
  # ...
  end
end

# After (リファクタリング後)
GRADE_THRESHOLDS = [
  { name: "伝説のカワウソ", min_accuracy: 98, min_wpm: 80 },
  { name: "熟練のカワウソ", min_accuracy: 90, min_wpm: 50 },
  # ...
]

def calculate_grade
  return if accuracy.nil? || wpm.nil?
  grade_data = GRADE_THRESHOLDS.find { |g| accuracy >= g[:min_accuracy] && wpm >= g[:min_wpm] }
  self.grade = grade_data ? grade_data[:name] : "赤ちゃんカワウソ"
end
```

テストが通れば、リファクタリングが成功したことが保証されます。

**3. 回帰バグの防止**

新機能追加時に、既存機能が壊れていないか自動確認できます：

```bash
# 新機能追加後にテスト実行
bundle exec rspec
# 158 examples, 0 failures, 30 pending
# ✅ 既存機能が壊れていない
```

**4. プラグマティックなアプローチによる進捗確保**

完璧を目指して0%より、80%を先に完成させる方が建設的です：

- Day 25: 158 examples, 128 passing (81%)
- Day 27: 7 examples, 7 passing (100%)
- **合計: 165 examples, 135 passing (82%)**

技術的負債は管理しつつ、プロジェクトの進捗を止めない戦略です。

**5. システムテストによるユーザー体験の保証**

モデルテストだけでは、ユーザーの実際の操作フローは検証できません。システムテストにより、**「タイピング練習時のキーハイライト」**というアプリの核心機能を保証できます：

```ruby
it "正しい文字を入力すると次のキーがハイライトされる" do
  login_as_user(user)
  visit lesson_path(lesson)

  expect(page).to have_selector('.key.ring-2[data-position="L2-R0"]')  # "h"

  input_field = page.find('[data-typing-target="input"]', visible: :all)
  input_field.send_keys("h")

  sleep 0.1

  expect(page).to have_selector('.key.ring-2[data-position="L0-R2"]')  # "e"
end
```

このテストにより、JavaScript + View + CSSの統合的な動作が保証されます。

---

#### 実装のポイント

**1. build() vs create()**

- `build()` - DB保存なし、バリデーションテスト向け
- `create()` - DB保存あり、スコープ・一意性制約テスト向け

```ruby
# バリデーションテスト（DB保存不要）
it "必須であること" do
  user = build(:user, email: nil)  # build() を使う
  expect(user).not_to be_valid
end

# スコープテスト（DB保存必要）
it "最近の記録順に取得すること" do
  old_record = create(:lesson_record, completed_at: 2.days.ago)  # create() を使う
  new_record = create(:lesson_record, completed_at: 1.day.ago)
  expect(LessonRecord.recent.first).to eq(new_record)
end
```

**2. sequence() の活用**

`Faker::Number.unique` はリトライ制限があるため、一意な値には `sequence()` を使う：

```ruby
# ❌ Fakerでエラー
factory :keymap_set do
  name { "キーマップ#{Faker::Number.unique.number(digits: 2)}" }
  # Faker::UniqueGenerator::RetryLimitExceeded
end

# ✅ sequenceで解決
factory :keymap_set do
  sequence(:name) { |n| "テストキーマップ#{n}" }
  sequence(:slug) { |n| "test-keymap-#{n}" }
end
```

**3. trait による多様なシナリオ**

```ruby
factory :lesson_record do
  # デフォルト値
  word_count { 10 }
  accuracy { 80.0 }

  trait :legendary do
    accuracy { 99.0 }
    typed_chars { 800 }
    duration_seconds { 60 }
  end

  trait :adult do
    accuracy { 95.0 }
    typed_chars { 600 }
    duration_seconds { 60 }
  end
end

# 使用例
lesson_record = build(:lesson_record, :legendary)
```

**4. privateメソッドのテスト**

Railsのコールバック（`before_save`, `after_create` など）はprivateメソッドとして実装されることが多い。`send(:method_name)` を使えば、privateメソッドを直接テストできる：

```ruby
lesson_record = build(:lesson_record, typed_chars: 500, duration_seconds: 60)
lesson_record.send(:calculate_wpm)  # private メソッドを直接呼び出し
expect(lesson_record.wpm).to eq(100)
```

**5. Capybaraのドライバー自動判定**

`rack_test`（JavaScript無効）と`selenium_chrome_headless`（JavaScript有効）で異なるAPIを持つため、ヘルパーメソッドでドライバーを自動判定する：

```ruby
def login_as_user(user = nil)
  user ||= create(:user)

  if page.driver.is_a?(Capybara::RackTest::Driver)
    # 高速だがJavaScript無効
    page.driver.post "/test/sessions", user_id: user.id
  else
    # 遅いがJavaScript有効
    visit "/test/sessions?user_id=#{user.id}"
  end

  user
end
```

**6. システムテストの速度最適化**

Day 27のタイピングハイライトテスト: **7 examples, 10.46秒**（1.5秒/example）

**高速化のポイント:**
- Headless Chrome（GUI不要）
- テスト用セッション管理（Google OAuth不要）
- 必要最小限のデータ作成（`hello`, `world`などシンプルな文字列）

```ruby
# シンプルなテストデータ
let(:lesson) { create(:lesson, items: [ "hello" ], count: 1) }

# 最小限のキーマップ設定
before do
  keymap_set.keymaps.find_by(layer: 0, key_position: "L2-R0").update(character: "h")
  keymap_set.keymaps.find_by(layer: 0, key_position: "L0-R2").update(character: "e")
  # ...
end
```

---

### Typnixプロジェクトでの実例

#### 実例1: AllowedEmailモデルのテスト（Day 28）

**ファイル**: `spec/models/allowed_email_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe AllowedEmail, type: :model do
  describe "validations" do
    it "メールアドレスが必須" do
      allowed_email = AllowedEmail.new(email: nil)
      expect(allowed_email).not_to be_valid
      expect(allowed_email.errors[:email]).to include("を入力してください")
    end

    it "有効なメールアドレス形式である必要がある" do
      allowed_email = AllowedEmail.new(email: "invalid-email")
      expect(allowed_email).not_to be_valid
      expect(allowed_email.errors[:email]).to be_present
    end

    it "大文字小文字を区別せずに一意性をチェック" do
      AllowedEmail.create!(email: "test@example.com")
      duplicate = AllowedEmail.new(email: "TEST@example.com")
      expect(duplicate).not_to be_valid
    end
  end

  describe "callbacks" do
    it "保存前にメールアドレスを小文字化する" do
      allowed_email = AllowedEmail.create!(email: "TEST@EXAMPLE.COM")
      expect(allowed_email.email).to eq("test@example.com")
    end
  end

  describe ".allowed?" do
    context "ログイン制限が有効な場合" do
      before do
        allow(Authentication).to receive(:restrict_login?).and_return(true)
      end

      it "許可リストに含まれるメールアドレスはtrueを返す" do
        AllowedEmail.create!(email: "allowed@example.com", active: true)
        expect(AllowedEmail.allowed?("allowed@example.com")).to be true
      end

      it "大文字小文字を区別せずにチェック" do
        AllowedEmail.create!(email: "test@example.com", active: true)
        expect(AllowedEmail.allowed?("TEST@EXAMPLE.COM")).to be true
      end
    end

    context "ログイン制限が無効な場合" do
      before do
        allow(Authentication).to receive(:restrict_login?).and_return(false)
      end

      it "どんなメールアドレスでもtrueを返す" do
        expect(AllowedEmail.allowed?("anyone@example.com")).to be true
      end
    end
  end
end
```

**テスト実行結果:**
```bash
bundle exec rspec spec/models/allowed_email_spec.rb
# 13 examples, 0 failures
```

**使用技術:**
- `allow().to receive().and_return()` でフィーチャーフラグをモック
- コールバックのテスト（`before_save :normalize_email`）
- 環境変数のモック（`Authentication.restrict_login?`）

#### 実例2: システムテストでのキーマップ設定（Day 27）

**課題:** KeymapSetは作成時に`after_create :copy_default_keymap`コールバックで全てのキー（288個）を自動生成する

```ruby
# ❌ 新規作成（エラー）
create(:keymap, :key_h, keymap_set: keymap_set)
# ActiveRecord::RecordInvalid: バリデーションに失敗しました: Key position はすでに存在します
```

**解決策:** 新規作成ではなく、既存のKeymapを更新

```ruby
# ✅ 既存レコードの更新（成功）
before do
  # "hello"と"world"を打つための最小限のキーマップを作成
  keymap_set.keymaps.find_by(layer: 0, key_position: "L2-R0").update(character: "h")
  keymap_set.keymaps.find_by(layer: 0, key_position: "L0-R2").update(character: "e")
  keymap_set.keymaps.find_by(layer: 0, key_position: "L2-R3").update(character: "l")
  keymap_set.keymaps.find_by(layer: 0, key_position: "R2-R2").update(character: "o")
  keymap_set.keymaps.find_by(layer: 0, key_position: "L1-R1").update(character: "w")
  # ...
end
```

**教訓:** モデルのコールバックがテストデータ作成に影響を与える場合、「作成」ではなく「更新」のアプローチを取る

#### 実例3: デフォルトキーマップとテストデータの衝突（Day 27）

**課題:** レイヤー切り替えのテストで"H"を使おうとしたが、デフォルトキーマップに既に"H"が存在

```ruby
# ❌ 意図しない動作
let(:lesson) { create(:lesson, items: [ "Hello" ]) }
before do
  keymap_set.keymaps.find_by(layer: 1, key_position: "L2-R0").update(character: "H")
end

it "Layer1キーがハイライトされる" do
  # 期待: Layer 1のL3-R3（Layer1キー）がハイライト
  # 実際: Layer 0のR1-R0（デフォルトキーマップの"H"）がハイライト
end
```

**原因:** JavaScriptのロジックがLayer 0から順に検索し、最初に見つかった文字を使用

**解決策:** デフォルトキーマップにない文字（"X"）を使用

```ruby
# ✅ デフォルトキーマップにない文字を使用
let(:lesson) { create(:lesson, items: [ "X" ]) }

before do
  # Layer 1に大文字"X"を追加（デフォルトキーマップにない文字）
  keymap_set.keymaps.find_by(layer: 1, key_position: "L2-R0").update(character: "X")
  # Layer 0のL2-R0は空文字に設定（Xを検索してもLayer 0で見つからないようにする）
  keymap_set.keymaps.find_by(layer: 0, key_position: "L2-R0").update(character: "")
  # レイヤー切り替えキー（Layer1/Lyr1）をLayer 0に追加
  keymap_set.keymaps.find_by(layer: 0, key_position: "L3-R3").update(character: "Layer1")
end

it "大文字が必要な場合はレイヤーボタンとターゲットキーの両方がハイライトされる" do
  login_as_user(user)
  visit lesson_path(lesson)

  # 1. Layer1キー（L3-R3）がハイライトされる ✅
  expect(page).to have_selector('.key.ring-2[data-position="L3-R3"]')

  # 2. "X"のキー（L2-R0）もハイライトされる ✅
  expect(page).to have_selector('.key.ring-2[data-position="L2-R0"]')
end
```

**教訓:** テストデータは本番データの状態を考慮し、衝突しない値を選ぶ

---

## 💡 まとめ

### 重要ポイント

- ✅ **テストは仕様書**: テストコードを読めば、モデルの仕様が理解できる
- ✅ **「あるべき姿」のテスト**: テストが通らない場合、実装を修正してテストに合わせる
- ✅ **プラグマティックなアプローチ**: 80-90%のテストを優先し、複雑なテストはskip
- ✅ **技術的負債の管理**: skipしたテストはTODOコメントで管理
- ✅ **モデルテスト vs システムテスト**: ビジネスロジックはモデルテスト、ユーザー体験はシステムテスト
- ✅ **build() vs create()**: バリデーションテストは`build()`, スコープテストは`create()`
- ✅ **テスト駆動開発（TDD）**: 理想的な動作を先にテストで定義し、実装をそれに合わせる

### テスト戦略チェックリスト

**Phase 1: モデルテスト（最優先）**
- [ ] バリデーション（必須項目、文字数制限、フォーマット）
- [ ] ビジネスロジック（WPM計算、グレード判定、slug生成）
- [ ] アソシエーション（belongs_to, has_many）
- [ ] インスタンスメソッド（#admin?, #official?, #to_lesson_info）
- [ ] クラスメソッド（.generate_next_slug, .available_tabs）

**Phase 2: システムテスト（E2E）**
- [ ] 認証フロー（ログイン、ログアウト、アクセス制御）
- [ ] レッスン閲覧フロー（一覧、詳細、タブ切り替え）
- [ ] 練習履歴閲覧フロー（一覧、期間フィルター、ページネーション）
- [ ] タイピング練習フロー（キーハイライト、指ガイド、レイヤー切り替え、完了画面）
- [ ] キーマップ編集フロー（CRUD、削除制限、キーマップ選択）

**Phase 3: CI/CD**
- [ ] GitHub Actionsでテスト自動実行
- [ ] RuboCop、Brakeman も統合
- [ ] PRマージ前の自動チェック

### テスト実行コマンド

```bash
# 全テスト実行
bundle exec rspec

# モデルテストのみ
bundle exec rspec spec/models

# システムテストのみ
bundle exec rspec spec/system

# 特定ファイル
bundle exec rspec spec/models/user_spec.rb

# 品質チェック
bundle exec rubocop
bundle exec brakeman --no-pager
```

### 次のステップ

このトピックを理解したら、以下に進むことをお勧めします：

- **GitHub Actions CI/CD設定**: `.github/workflows/ci.yml` でテスト自動実行
- **テストカバレッジ向上**: pending解消、新機能追加時のテスト追加
- **継続的なメンテナンス**: リファクタリング時にテストも更新

---

## 🔗 関連教材

- [セキュリティベストプラクティス](../03_advanced/06_security_best_practices.md)
- [データベース設計と段階的マイグレーション](../03_advanced/07_database_design_and_migration.md)
- [レビューテスト: RSpecテスト追加](../../reviews/review_08_rspec_testing_strategy.md)

---

## 📝 演習問題（オプション）

### 問題1: バリデーションテストの作成

以下のモデルに対して、バリデーションテストを作成してください：

```ruby
class Category < ApplicationRecord
  validates :name, presence: true, length: { maximum: 50 }
  validates :tab, presence: true, uniqueness: true
  validates :display_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
```

<details>
<summary>解答例を表示</summary>

```ruby
require "rails_helper"

RSpec.describe Category, type: :model do
  describe "バリデーション" do
    describe "name" do
      it "必須であること" do
        category = build(:category, name: nil)
        expect(category).not_to be_valid
        expect(category.errors[:name]).to include("を入力してください")
      end

      it "50文字以下であること" do
        expect(build(:category, name: "a" * 50)).to be_valid
        expect(build(:category, name: "a" * 51)).not_to be_valid
      end
    end

    describe "tab" do
      it "必須であること" do
        category = build(:category, tab: nil)
        expect(category).not_to be_valid
      end

      it "一意であること" do
        create(:category, tab: "basics")
        duplicate = build(:category, tab: "basics")
        expect(duplicate).not_to be_valid
      end
    end

    describe "display_order" do
      it "整数であること" do
        expect(build(:category, display_order: 1.5)).not_to be_valid
        expect(build(:category, display_order: 1)).to be_valid
      end

      it "0以上であること" do
        expect(build(:category, display_order: -1)).not_to be_valid
        expect(build(:category, display_order: 0)).to be_valid
      end
    end
  end
end
```

**解説:**
- `build()` でDB保存なしでバリデーションテスト
- 境界値テスト（50文字、51文字、0、-1）で境界条件を明確化
- 一意性制約のテストは `create()` を使う

</details>

---

### 問題2: システムテストの作成

以下の仕様に対して、システムテストを作成してください：

**仕様:**
- ログインユーザーが `/my/history` にアクセスすると、練習履歴一覧が表示される
- 期間フィルター（全期間・直近1ヶ月・直近1週間）でタブ切り替え可能
- 未ログインユーザーは `/my/history` にアクセスできない（ルートページにリダイレクト）

<details>
<summary>解答例を表示</summary>

```ruby
require "rails_helper"

RSpec.describe "練習履歴閲覧", type: :system do
  let(:user) { create(:user) }

  describe "練習履歴一覧" do
    it "ログインユーザーが練習履歴一覧を閲覧できる" do
      # テストデータ作成
      create(:lesson_record, user: user, completed_at: 2.days.ago)
      create(:lesson_record, user: user, completed_at: 1.day.ago)

      login_as_user(user)
      visit my_history_path

      # 練習履歴一覧が表示される
      expect(page).to have_content("練習履歴")
      expect(page).to have_selector("table tbody tr", count: 2)
    end

    it "未ログインユーザーはアクセスできない" do
      visit my_history_path

      # ルートページにリダイレクトされる
      expect(page).to have_current_path(root_path)
    end
  end

  describe "期間フィルター", js: true do
    before do
      # テストデータ作成
      create(:lesson_record, user: user, completed_at: 2.months.ago)
      create(:lesson_record, user: user, completed_at: 2.weeks.ago)
      create(:lesson_record, user: user, completed_at: 1.day.ago)
    end

    it "全期間タブで全ての記録が表示される" do
      login_as_user(user)
      visit my_history_path

      click_link "全期間"
      sleep 0.1

      expect(page).to have_selector("table tbody tr", count: 3)
    end

    it "直近1ヶ月タブで1ヶ月以内の記録のみ表示される" do
      login_as_user(user)
      visit my_history_path

      click_link "直近1ヶ月"
      sleep 0.1

      expect(page).to have_selector("table tbody tr", count: 2)
    end

    it "直近1週間タブで1週間以内の記録のみ表示される" do
      login_as_user(user)
      visit my_history_path

      click_link "直近1週間"
      sleep 0.1

      expect(page).to have_selector("table tbody tr", count: 1)
    end
  end
end
```

**解説:**
- `js: true` でJavaScriptを有効化（Turbo Frames動作確認）
- `sleep 0.1` でTurbo Framesの処理を待つ
- テストデータは `before do` ブロックで一度だけ作成

</details>

---

**作成日**: 2026-01-02
**難易度**: 🔴 上級
**推定学習時間**: 2.5〜3時間
