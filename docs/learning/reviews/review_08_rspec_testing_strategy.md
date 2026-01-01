# Review Test #08: RSpecテスト追加

**難易度**: 🔴 上級
**推定時間**: 30分〜1時間
**学習トピック**: [RSpecによるテスト戦略](../topics/03_advanced/08_rspec_testing_strategy.md)

---

## 前提条件

あなたはTypnixプロジェクトのコードレビュアーです。
以下のPRがレビュー待ちになっています。

## PR概要

- **タイトル**: RSpecテストを追加してカバレッジ100%を達成
- **変更ファイル数**: 15ファイル
- **目的**: テストカバレッジを0%から100%に向上させ、品質保証を強化する

## 変更内容

### 1. `spec/models/user_spec.rb` (新規作成)

```ruby
require "rails_helper"

RSpec.describe User, type: :model do
  describe "バリデーション" do
    it "emailが必須であること" do
      user = FactoryBot.build(:user, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "emailが254文字以下であること" do
      user = FactoryBot.build(:user, email: "a" * 246 + "@test.com")
      expect(user).not_to be_valid
    end

    it "usernameが必須であること" do
      user = FactoryBot.build(:user, username: nil)
      expect(user).not_to be_valid
    end

    it "usernameが一意であること" do
      FactoryBot.create(:user, username: "testuser")
      user = FactoryBot.build(:user, username: "testuser")
      expect(user).not_to be_valid
    end

    it "usernameが予約語は使用不可であること" do
      user = FactoryBot.build(:user, username: "admin")
      expect(user).not_to be_valid
    end
  end

  describe "#admin?" do
    it "ADMIN_EMAILSに含まれる場合、trueを返すこと" do
      user = FactoryBot.build(:user, email: "admin@example.com")
      expect(user.admin?).to be true
    end
  end

  describe "#can_change_username?" do
    it "username_changed_atがnilの場合、trueを返すこと" do
      user = FactoryBot.build(:user, username_changed_at: nil)
      expect(user.can_change_username?).to be true
    end

    it "24時間以内の場合、falseを返すこと" do
      user = FactoryBot.build(:user, username_changed_at: 12.hours.ago)
      expect(user.can_change_username?).to be false
    end
  end

  describe ".generate_unique_username" do
    it "メールアドレスから@の前部分を抽出してusernameを生成すること" do
      username = User.generate_unique_username("test.user@example.com")
      expect(username).to eq("test.user")
    end

    it "既存のusernameと重複する場合、数字を付与すること" do
      FactoryBot.create(:user, username: "testuser")
      username = User.generate_unique_username("testuser@example.com")
      expect(username).to eq("testuser1")
    end
  end
end
```

**約40行のテストケース**

### 2. `spec/models/lesson_record_spec.rb` (新規作成)

```ruby
require "rails_helper"

RSpec.describe LessonRecord, type: :model do
  describe "バリデーション" do
    let(:lesson_record) { FactoryBot.build(:lesson_record) }

    it "word_countが必須であること" do
      lesson_record.word_count = nil
      expect(lesson_record).not_to be_valid
    end

    it "accuracyが0以上100以下であること" do
      expect(FactoryBot.build(:lesson_record, accuracy: -0.1)).not_to be_valid
      expect(FactoryBot.build(:lesson_record, accuracy: 0)).to be_valid
      expect(FactoryBot.build(:lesson_record, accuracy: 100)).to be_valid
      expect(FactoryBot.build(:lesson_record, accuracy: 100.1)).not_to be_valid
    end
  end

  describe "WPM計算" do
    it "typed_charsとduration_secondsからWPMを自動計算すること" do
      lesson_record = FactoryBot.create(:lesson_record, typed_chars: 500, duration_seconds: 60)
      expect(lesson_record.wpm).to eq(100)
    end

    it "duration_secondsが0の場合、WPMを計算しないこと" do
      lesson_record = FactoryBot.create(:lesson_record, typed_chars: 500, duration_seconds: 0)
      expect(lesson_record.wpm).to be_nil
    end

    it "小数点以下を四捨五入すること" do
      lesson_record = FactoryBot.create(:lesson_record, typed_chars: 333, duration_seconds: 60)
      expect(lesson_record.wpm).to eq(67)
    end
  end

  describe "グレード判定" do
    it "正答率98%以上、WPM 80以上で「伝説のカワウソ」になること" do
      lesson_record = FactoryBot.create(:lesson_record, accuracy: 99.0, typed_chars: 800, duration_seconds: 60)
      expect(lesson_record.grade).to eq("legendary_otter")
    end

    it "正答率90%以上、WPM 50以上で「熟練のカワウソ」になること" do
      lesson_record = FactoryBot.create(:lesson_record, accuracy: 95.0, typed_chars: 600, duration_seconds: 60)
      expect(lesson_record.grade).to eq("adult_otter")
    end

    it "正答率97%でもWPM 49なら「熟練のカワウソ」にならないこと" do
      lesson_record = FactoryBot.create(:lesson_record, accuracy: 97.0, typed_chars: 490, duration_seconds: 120)
      expect(lesson_record.grade).to eq("young_otter")
    end
  end

  describe "#grade_emoji" do
    it "グレードの絵文字を返すこと" do
      lesson_record = FactoryBot.create(:lesson_record, accuracy: 95.0, typed_chars: 600, duration_seconds: 60)
      expect(lesson_record.grade_emoji).to eq("🦦")
    end
  end
end
```

**約50行のテストケース**

### 3. `spec/system/typing_spec.rb` (新規作成)

```ruby
require "rails_helper"

RSpec.describe "タイピング練習", type: :system do
  let(:user) { FactoryBot.create(:user) }
  let(:category) { FactoryBot.create(:category, tab: "basics", published: true) }
  let(:lesson) { FactoryBot.create(:lesson, category: category, items: [ "hello", "world", "test", "ruby", "rails" ], count: 5) }
  let(:keymap_set) { FactoryBot.create(:keymap_set, user: user, name: "テスト用キーマップ") }

  before do
    # 全ての文字をキーマップに設定
    ("a".."z").each_with_index do |char, index|
      layer = index / 12
      position = "L#{layer}-R#{index % 12}"
      FactoryBot.create(:keymap, keymap_set: keymap_set, layer: layer, key_position: position, character: char)
    end

    user.update(active_keymap_set: keymap_set)
  end

  describe "初期表示", js: true do
    it "レッスン画面が表示される" do
      login_as_user(user)
      visit lesson_path(lesson)

      expect(page).to have_selector("[data-typing-target='lessonScreen']", visible: true)
    end

    it "最初の文字に対応するキーがハイライトされる" do
      login_as_user(user)
      visit lesson_path(lesson)

      # 最初の単語の最初の文字がハイライトされる
      expect(page).to have_selector('.key.ring-2')
    end

    it "対応する指ガイドもハイライトされる" do
      login_as_user(user)
      visit lesson_path(lesson)

      expect(page).to have_selector('.finger-guide.ring-2')
    end
  end

  describe "文字入力", js: true do
    it "全ての文字を入力すると完了画面が表示される" do
      login_as_user(user)
      visit lesson_path(lesson)

      # 全ての単語を入力
      input_field = page.find('[data-typing-target="input"]', visible: :all)
      [ "hello", "world", "test", "ruby", "rails" ].each do |word|
        input_field.send_keys(word)
        sleep 0.5
      end

      # 完了画面が表示される
      expect(page).to have_selector('[data-typing-target="completionScreen"]', visible: true, wait: 10)
    end

    it "統計情報が正確に表示される" do
      login_as_user(user)
      visit lesson_path(lesson)

      input_field = page.find('[data-typing-target="input"]', visible: :all)
      [ "hello", "world", "test", "ruby", "rails" ].each do |word|
        input_field.send_keys(word)
        sleep 0.5
      end

      expect(page).to have_selector('[data-typing-target="completionScreen"]', visible: true, wait: 10)

      # 統計情報の各要素が表示される
      expect(page).to have_selector('[data-typing-target="accuracyDisplay"]')
      expect(page).to have_selector('[data-typing-target="wpmDisplay"]')
      expect(page).to have_selector('[data-typing-target="timeDisplay"]')
      expect(page).to have_selector('[data-typing-target="mistakesDisplay"]')
    end
  end

  describe "エラー処理", js: true do
    it "間違った文字を入力すると赤くハイライトされる" do
      login_as_user(user)
      visit lesson_path(lesson)

      input_field = page.find('[data-typing-target="input"]', visible: :all)
      input_field.send_keys("x")  # 間違った文字

      sleep 0.1

      display_area = page.find('[data-typing-target="display"]')
      expect(display_area).to have_selector('span.bg-red-100')
    end

    it "BackSpaceで削除すると前の状態に戻る" do
      login_as_user(user)
      visit lesson_path(lesson)

      input_field = page.find('[data-typing-target="input"]', visible: :all)
      input_field.send_keys("h")
      sleep 0.1

      # BackSpaceで削除
      input_field.send_keys(:backspace)
      sleep 0.1

      # 最初の文字に戻る
      expect(page).to have_selector('.key.ring-2')
    end
  end
end
```

**約80行のテストケース**

### 4. `spec/factories/keymaps.rb` (新規作成)

```ruby
FactoryBot.define do
  factory :keymap do
    association :keymap_set
    association :user

    layer { 0 }
    sequence(:key_position) { |n| "L#{n % 6}-R#{n / 6}" }
    character { "a" }

    trait :key_h do
      layer { 0 }
      key_position { "L2-R0" }
      character { "h" }
    end

    trait :key_e do
      layer { 0 }
      key_position { "L0-R2" }
      character { "e" }
    end

    # ... 他の文字のtraitも同様
  end
end
```

**約30行のファクトリ定義**

---

## レビュー課題

### Q1. 基本的なテスト問題（初級）🟢

以下のテストコードには3つの基本的な問題があります。それぞれ指摘してください。

1. `FactoryBot.build` と `FactoryBot.create` の使い分けに関する問題
2. FactoryBotのメソッド呼び出しに関する問題
3. テストの構造化（describe, context）に関する問題

**回答時間の目安**: 5分

<details>
<summary>解答を表示</summary>

### A1. 基本的なテスト問題

**1. `FactoryBot.build` と `FactoryBot.create` の使い分けに関する問題:**

```ruby
# ❌ 問題のあるコード
describe "WPM計算" do
  it "typed_charsとduration_secondsからWPMを自動計算すること" do
    lesson_record = FactoryBot.create(:lesson_record, typed_chars: 500, duration_seconds: 60)
    expect(lesson_record.wpm).to eq(100)
  end
end
```

**問題点:**
- WPM計算は `before_save` コールバックで実行されるため、`create` を使うのは正しい
- しかし、**privateメソッドを直接テストする方が適切**

**改善案:**
```ruby
# ✅ 改善版
describe "WPM計算" do
  it "typed_charsとduration_secondsからWPMを自動計算すること" do
    lesson_record = build(:lesson_record, typed_chars: 500, duration_seconds: 60)
    lesson_record.send(:calculate_wpm)  # private メソッドを直接呼び出し
    # CPM = (500 / 60) * 60 = 500
    # WPM = 500 / 5 = 100
    expect(lesson_record.wpm).to eq(100)
  end
end
```

**理由:**
- `build()` を使えばDB保存なしでテストできる（高速）
- `send(:calculate_wpm)` でprivateメソッドを直接テストできる
- コールバックに依存せず、ロジック自体をテストできる

**2. FactoryBotのメソッド呼び出しに関する問題:**

```ruby
# ❌ 問題のあるコード
it "emailが必須であること" do
  user = FactoryBot.build(:user, email: nil)
  expect(user).not_to be_valid
end
```

**問題点:**
- `FactoryBot.build` と書く必要はない（冗長）

**改善案:**
```ruby
# ✅ 改善版
it "emailが必須であること" do
  user = build(:user, email: nil)
  expect(user).not_to be_valid
end
```

**理由:**
- `rails_helper.rb` で `config.include FactoryBot::Syntax::Methods` を設定すれば、`build`, `create` をそのまま使える

**3. テストの構造化（describe, context）に関する問題:**

```ruby
# ❌ 問題のあるコード
describe "グレード判定" do
  it "正答率98%以上、WPM 80以上で「伝説のカワウソ」になること" do
    # ...
  end

  it "正答率90%以上、WPM 50以上で「熟練のカワウソ」になること" do
    # ...
  end
end
```

**問題点:**
- グレード別に `context` で分けると可読性が向上する

**改善案:**
```ruby
# ✅ 改善版
describe "グレード判定" do
  context "伝説のカワウソ級" do
    it "正答率98%以上、WPM 80以上で「伝説のカワウソ」になること" do
      # ...
    end

    it "正答率98%、WPM 80で「伝説のカワウソ」になること（境界値）" do
      # ...
    end
  end

  context "熟練のカワウソ級" do
    it "正答率90%以上、WPM 50以上で「熟練のカワウソ」になること" do
      # ...
    end

    it "正答率97%でもWPM 49なら「熟練のカワウソ」にならないこと" do
      # ...
    end
  end
end
```

**理由:**
- `describe` はメソッドやクラスの説明、`context` は特定の状況・条件を表現
- グレード別に `context` で分けると、テスト結果が階層的に表示されて理解しやすい

</details>

---

### Q2. 「あるべき姿」のテスト哲学（中級）🟡

以下の3つのテストには、「あるべき姿」のテスト哲学に反する問題があります。それぞれ指摘し、改善してください。

1. エラーメッセージが英語のまま（日本語化すべき）
2. グレード名が英語のまま（日本語化すべき）
3. 環境変数のモックがない（テストが環境に依存）

**回答時間の目安**: 10分

<details>
<summary>解答を表示</summary>

### A2. 「あるべき姿」のテスト哲学

**1. エラーメッセージが英語のまま（日本語化すべき）:**

```ruby
# ❌ 問題のあるコード
it "emailが必須であること" do
  user = build(:user, email: nil)
  expect(user).not_to be_valid
  expect(user.errors[:email]).to include("can't be blank")  # 英語で妥協
end
```

**問題点:**
- エラーメッセージが英語のまま
- ユーザーには日本語で表示すべき

**改善案:**
```ruby
# ✅ 改善版
it "emailが必須であること" do
  user = build(:user, email: nil)
  expect(user).not_to be_valid
  expect(user.errors[:email]).to include("を入力してください")  # 日本語化
end
```

**実装の修正:**
```yaml
# config/locales/ja.yml
ja:
  activerecord:
    attributes:
      user:
        email: "メールアドレス"
        username: "ユーザー名"
    errors:
      messages:
        blank: "を入力してください"
        taken: "はすでに存在します"
        invalid: "は不正な値です"
```

**教訓:**
- **テストが通らない場合、実装を修正してテストに合わせる**（テストを歪めない）
- テストは「あるべき姿」を定義する仕様書

**2. グレード名が英語のまま（日本語化すべき）:**

```ruby
# ❌ 問題のあるコード
it "正答率98%以上、WPM 80以上で「伝説のカワウソ」になること" do
  lesson_record = create(:lesson_record, accuracy: 99.0, typed_chars: 800, duration_seconds: 60)
  expect(lesson_record.grade).to eq("legendary_otter")  # 英語のまま
end
```

**問題点:**
- テストの説明は「伝説のカワウソ」（日本語）
- 実際の値は `"legendary_otter"`（英語）
- ユーザーには日本語で表示すべき

**改善案:**
```ruby
# ✅ 改善版
it "正答率98%以上、WPM 80以上で「伝説のカワウソ」になること" do
  lesson_record = build(:lesson_record, :legendary)
  lesson_record.send(:calculate_wpm)
  lesson_record.send(:calculate_grade)
  expect(lesson_record.grade).to eq("伝説のカワウソ")  # 日本語化
end
```

**実装の修正:**
```ruby
# app/models/lesson_record.rb
def calculate_grade
  return if accuracy.nil? || wpm.nil?

  if accuracy >= 98 && wpm >= 80
    self.grade = "伝説のカワウソ"
  elsif accuracy >= 90 && wpm >= 50
    self.grade = "熟練のカワウソ"
  elsif accuracy >= 80 && wpm >= 30
    self.grade = "若手のカワウソ"
  elsif accuracy >= 70 && wpm >= 15
    self.grade = "子どものカワウソ"
  else
    self.grade = "赤ちゃんカワウソ"
  end
end
```

**教訓:**
- データベースのカラムにも日本語を保存する（ユーザーが直接目にする情報）
- 英語のシンボルではなく、日本語の文字列を使う

**3. 環境変数のモックがない（テストが環境に依存）:**

```ruby
# ❌ 問題のあるコード
describe "#admin?" do
  it "ADMIN_EMAILSに含まれる場合、trueを返すこと" do
    user = build(:user, email: "admin@example.com")
    expect(user.admin?).to be true  # 環境変数に依存
  end
end
```

**問題点:**
- `ENV["ADMIN_EMAILS"]` に依存
- テスト環境で環境変数が設定されていない場合、失敗する

**改善案:**
```ruby
# ✅ 改善版
describe "#admin?" do
  it "ADMIN_EMAILSに含まれる場合、trueを返すこと" do
    allow(ENV).to receive(:[]).with("ADMIN_EMAILS").and_return("admin@example.com, admin2@example.com")
    user = build(:user, email: "admin@example.com")
    expect(user.admin?).to be true
  end

  it "ADMIN_EMAILSに含まれない場合、falseを返すこと" do
    allow(ENV).to receive(:[]).with("ADMIN_EMAILS").and_return("admin@example.com")
    user = build(:user, email: "user@example.com")
    expect(user.admin?).to be false
  end
end
```

**教訓:**
- 環境変数やフィーチャーフラグは `allow().to receive().and_return()` でモック
- テストが環境に依存しないようにする

</details>

---

### Q3. プラグマティックなアプローチ（中級〜上級）🟡🔴

以下の3つのシナリオについて、プラグマティックなアプローチで対応してください。

1. `active_keymap_set_id` NOT NULL制約で `create()` が失敗するテストをどうすべきか？
2. 全ての文字（a-z）をキーマップに設定するテストデータ作成の問題点は？
3. システムテストで全単語を入力するテストの問題点は？

**回答時間の目安**: 15分

<details>
<summary>解答を表示</summary>

### A3. プラグマティックなアプローチ

**1. `active_keymap_set_id` NOT NULL制約で `create()` が失敗するテストをどうすべきか？**

**シナリオ:**
```ruby
it "usernameが一意であること" do
  create(:user, username: "testuser")  # ❌ PG::NotNullViolation エラー
  user = build(:user, username: "testuser")
  expect(user).not_to be_valid
end
```

**問題点:**
- `User.create!` すると、`active_keymap_set_id` NOT NULL制約でエラー
- Railsのトランザクション順序の問題（INSERT → NOT NULL制約チェック → after_createコールバック）

**プラグマティックなアプローチ:**
```ruby
# ✅ 一旦skipして、TODOで管理
it "usernameが一意であること" do
  # TODO: createを使うテストは active_keymap_set の制約で一旦スキップ
  # 解決策: FactoryBotのカスタム戦略 or User modelリファクタリング
  skip "createを使うテストは active_keymap_set の制約で一旦保留"
end
```

**ポイント:**
- **80-90%のテストを先に完成させる**（完璧を目指して0%より建設的）
- `skip` で一旦スキップし、TODOコメントで「なぜ」「どう解決するか」を記録
- 技術的負債として管理し、時間のある時に解消

**Day 25後の解決策:**
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

  validate :must_have_active_keymap_set_after_creation

  private

  def must_have_active_keymap_set_after_creation
    return if new_record?
    return if active_keymap_set_id.present?
    errors.add(:active_keymap_set, "は必須です")
  end
end
```

**教訓:**
- プラグマティックに進めることで、システムテスト実装時に根本解決できた
- 完璧を目指して止まるより、先に進んで後で解決する方が建設的

**2. 全ての文字（a-z）をキーマップに設定するテストデータ作成の問題点は？**

```ruby
# ❌ 問題のあるコード
before do
  # 全ての文字をキーマップに設定
  ("a".."z").each_with_index do |char, index|
    layer = index / 12
    position = "L#{layer}-R#{index % 12}"
    create(:keymap, keymap_set: keymap_set, layer: layer, key_position: position, character: char)
  end
end
```

**問題点:**
- **KeymapSetは作成時に`after_create :copy_default_keymap`コールバックで全てのキー（288個）を自動生成**
- 新規作成しようとすると、一意性制約違反エラー
- 26個のキーを作成しようとして、全てエラー

**プラグマティックなアプローチ:**
```ruby
# ✅ 既存レコードの更新（Day 27の解決策）
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

**ポイント:**
- **新規作成ではなく、既存レコードの更新**
- 必要最小限のキーだけを設定（"hello", "world"に必要な文字のみ）
- テストデータはシンプルに保つ

**教訓:**
- モデルのコールバックがテストデータ作成に影響を与える場合、「作成」ではなく「更新」のアプローチを取る
- 全ての文字を設定するのではなく、テストに必要な最小限のデータだけを作成

**3. システムテストで全単語を入力するテストの問題点は？**

```ruby
# ❌ 問題のあるコード
describe "文字入力", js: true do
  let(:lesson) { create(:lesson, items: [ "hello", "world", "test", "ruby", "rails" ], count: 5) }

  it "全ての文字を入力すると完了画面が表示される" do
    login_as_user(user)
    visit lesson_path(lesson)

    input_field = page.find('[data-typing-target="input"]', visible: :all)
    [ "hello", "world", "test", "ruby", "rails" ].each do |word|
      input_field.send_keys(word)
      sleep 0.5
    end

    expect(page).to have_selector('[data-typing-target="completionScreen"]', visible: true, wait: 10)
  end
end
```

**問題点:**
- 5単語（27文字）を入力する必要がある
- 実行時間が長い（`sleep 0.5` × 5 = 2.5秒 + タイピング時間）
- テストが複雑で、失敗時の原因特定が困難

**プラグマティックなアプローチ:**
```ruby
# ✅ シンプルなテスト（Day 27の解決策）
describe "タイピング完了", js: true do
  let(:lesson) { create(:lesson, items: [ "he" ], count: 1) }

  it "全ての文字を入力すると完了画面が表示される" do
    login_as_user(user)
    visit lesson_path(lesson)

    # "h"と"e"を入力
    input_field = page.find('[data-typing-target="input"]', visible: :all)
    input_field.send_keys("he")

    # 完了画面が表示されるまで待機（最大5秒）
    expect(page).to have_selector('[data-typing-target="completionScreen"]', visible: true, wait: 5)
  end
end
```

**ポイント:**
- **必要最小限のデータ**（"he"の2文字だけ）
- 実行時間が短い（0.1秒程度）
- テストの意図が明確（「完了画面が表示される」ことを検証）

**教訓:**
- システムテストは「ユーザー体験の保証」が目的
- 全ての文字パターンを網羅する必要はない（モデルテストで代用）
- **シンプルかつ本質的なテスト**を優先

**Day 27の実行結果:**
```bash
bundle exec rspec spec/system/typing_highlight_spec.rb
# 7 examples, 0 failures
# 実行時間: 10.46秒（1.5秒/example）
```

**コード削減効果:**
- 削除: 約50行（5単語の入力ロジック、26個のキーマップ作成）
- 追加: 約20行（2文字の入力ロジック、7個のキーマップ更新）
- **純削減: 約30行**

</details>

---

### Q4. テストとCI/CDの統合（上級）🔴

以下の質問に答えてください：

1. テストカバレッジ100%を目指すことの問題点は？
2. テストの優先順位をどう判断すべきか？
3. テストのメンテナンス戦略は？

**回答時間の目安**: 10分

<details>
<summary>解答を表示</summary>

### A4. テストとCI/CDの統合

#### 1. テストカバレッジ100%を目指すことの問題点は？

**問題点:**

**a. 時間対効果が低い**
- 100%を目指すと、trivialなコードまでテストを書く必要がある
- 例: getter/setter、単純な委譲メソッド、定数の定義

**b. メンテナンスコストが高い**
- テストケースが多すぎると、仕様変更時の修正コストが高い
- 本質的でないテストが多いと、重要なテストが埋もれる

**c. 完璧主義に陥る**
- 100%を達成するまで先に進めなくなる
- Day 25の例: 158 examples中30 examples（19%）がpendingでも、81%の完成度で先に進んだ

**プラグマティックなアプローチ:**
- **80-90%のカバレッジを目指す**
- 重要なビジネスロジックを優先
- trivialなコードはテストを省略（または後回し）

**Typnixプロジェクトの実例:**
```
Day 25: 158 examples, 128 passing (81%)
Day 27: 7 examples, 7 passing (100%)
合計: 165 examples, 135 passing (82%)
```

**教訓:**
- 完璧を目指して0%より、80%を先に完成させる方が建設的
- skipしたテストはTODOで管理し、時間のある時に解消

---

#### 2. テストの優先順位をどう判断すべきか？

**優先順位の判断基準（Day 25-27で確立）:**

| 基準 | 説明 | 例 |
|------|------|-----|
| **1. ビジネス価値** | ユーザーにとっての重要度 | タイピング練習のキーハイライト（最重要） |
| **2. リスク** | 壊れた時の影響度 | WPM計算、グレード判定（高リスク） |
| **3. 変更頻度** | コード変更が多い箇所ほど優先 | ユーザー認証（変更頻度高） |
| **4. 実装コスト** | 時間対効果 | シンプルなテストを優先 |

**Typnixプロジェクトの優先順位:**

**Phase 1: モデルテスト（最優先）**
- User: 認証ロジック、バリデーション、ユーザー名変更制限
- LessonRecord: WPM計算、グレード判定、統計計算
- Lesson: visible_toスコープ、権限チェック
- Category: タブ機能、公開制御
- KeymapSet: slug生成、バリデーション
- Share: トークン生成、delegate動作

**Phase 2: システムテスト（E2E）**
- **クリティカルパス（優先度最高）**
  - 認証フロー（30分）
  - レッスン閲覧フロー（20分）
  - 練習履歴閲覧フロー（20分）
  - タイピング練習のキーハイライト（70分）
- **重要なユーザーフロー（中優先度）**
  - キーマップ閲覧・選択フロー
  - キーマップ編集フロー（CRUD）
- **補助的な機能（低優先度）**
  - シェア機能
  - 管理者ダッシュボード

**スキップ推奨:**
- ❌ タイピング入力の完全シミュレーション（JavaScriptが複雑、モデルテストで代用）
- ❌ レスポンシブ対応（ビジュアル確認は手動の方が効率的）

**教訓:**
- **ビジネス価値 × リスク** が高いものを優先
- システムテストは「ユーザー体験の保証」に絞る
- 完全なシミュレーションより、シンプルかつ本質的なテスト

---

#### 3. テストのメンテナンス戦略は？

**a. テストが仕様書の役割を果たすようにする**

```ruby
# ✅ 良い例（仕様が明確）
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

このテストを読めば、「正答率98%以上かつWPM 80以上で伝説のカワウソ級」という仕様が理解できる。

**b. DRY原則を適用しすぎない**

```ruby
# ❌ 悪い例（DRY原則を適用しすぎ）
shared_examples "grade_test" do |grade_name, accuracy, wpm|
  it "正答率#{accuracy}%、WPM #{wpm}で「#{grade_name}」になること" do
    lesson_record = build(:lesson_record, accuracy: accuracy, typed_chars: wpm * 5, duration_seconds: 60)
    lesson_record.send(:calculate_wpm)
    lesson_record.send(:calculate_grade)
    expect(lesson_record.grade).to eq(grade_name)
  end
end

describe "グレード判定" do
  include_examples "grade_test", "伝説のカワウソ", 99.0, 80
  include_examples "grade_test", "熟練のカワウソ", 95.0, 50
end
```

**問題点:**
- 可読性が低い（shared_examplesの定義を探す必要がある）
- 特定のグレードだけテストしたい場合、変更が困難

```ruby
# ✅ 良い例（適度な重複を許容）
describe "グレード判定" do
  context "伝説のカワウソ級" do
    it "正答率98%以上、WPM 80以上で「伝説のカワウソ」になること" do
      lesson_record = build(:lesson_record, :legendary)
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
  end
end
```

**教訓:**
- **テストコードはドキュメント**
- 適度な重複を許容し、可読性を優先

**c. 技術的負債の管理**

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

**d. 継続的なメンテナンス**

**新機能追加時:**
- 機能追加と同時にテストも追加
- テストが通らない場合、実装を修正してテストに合わせる

**リファクタリング時:**
- テストが通れば、リファクタリング成功
- テストが失敗したら、リファクタリングを見直す

**品質チェック:**
```bash
# リモートプッシュ前に必ず実行
bundle exec rubocop
bundle exec brakeman --no-pager
bundle exec rspec
```

**GitHub Actions CI/CD（将来実装）:**
```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4.4
      - name: Install dependencies
        run: bundle install
      - name: Run RuboCop
        run: bundle exec rubocop
      - name: Run Brakeman
        run: bundle exec brakeman --no-pager
      - name: Run RSpec
        run: bundle exec rspec
```

**教訓:**
- テストは「書いて終わり」ではなく、継続的にメンテナンスする
- 技術的負債はTODOで管理し、時間のある時に解消
- CI/CDで自動チェックし、品質を担保

</details>

---

## 総合評価

### 基準

- **Q1を正解**: RSpecとFactoryBotの基本を理解している
- **Q2を正解**: 「あるべき姿」のテスト哲学を理解している
- **Q3を正解**: プラグマティックなアプローチを実践できる
- **Q4を正解**: テスト戦略を立案し、継続的にメンテナンスできる

### 次のステップ

- **Q1のみ正解**: [RSpecによるテスト戦略](../topics/03_advanced/08_rspec_testing_strategy.md)のモデルテストセクションを復習してください
- **Q1-Q2正解**: 「あるべき姿」のテスト哲学を理解しています。次はプラグマティックなアプローチを学びましょう
- **Q1-Q3正解**: テスト戦略の基本を理解しています。次はCI/CD統合を学びましょう
- **全問正解**: RSpecテスト戦略を完全に理解しています。実際のプロジェクトで実践し、継続的に改善してください

## 参考資料

- [RSpecによるテスト戦略](../topics/03_advanced/08_rspec_testing_strategy.md)
- [データベース設計と段階的マイグレーション](../topics/03_advanced/07_database_design_and_migration.md)
- Day 25の日報: `docs/daily_reports/2025-12-25.md`
- Day 27の日報: `docs/daily_reports/2025-12-27.md`
- 実際のPR: #84, #85, #93

---

**作成日**: 2026-01-02
**難易度**: 🔴 上級
**推定時間**: 30分〜1時間
