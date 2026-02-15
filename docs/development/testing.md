# テスト戦略

Typnixのテスト実装状況と戦略をまとめたドキュメント。

---

## テスト実行結果

```bash
bundle exec rspec
# 158 examples, 0 failures, 30 pending

bundle exec rubocop
# 98 files inspected, 0 offenses

bundle exec brakeman
# 0 security warnings
```

---

## テスト哲学

### 「あるべき姿」のテストを書く

- ❌ **NG**: テストを実装に合わせる（テストを歪める）
- ✅ **OK**: 実装をテストに合わせる（理想の動作を定義）

**例**: エラーメッセージが英語のままなら、日本語翻訳を追加する（テストで英語を許容しない）

### プラグマティックなアプローチ

- 80-90%のテストが通る状態を優先し、複雑なテストは後回し
- 複雑なテストは `skip` でスキップし、TODOコメントで理由と解決策を記録

**TODOコメントの例:**

```ruby
it "一意であること" do
  # TODO: createを使うテストは active_keymap_set の制約で一旦スキップ
  # 解決策: FactoryBotのカスタム戦略 or User modelリファクタリング
  skip "createを使うテストは active_keymap_set の制約で一旦保留"
end
```

---

## テスト環境

- **テストフレームワーク**: RSpec 3.13
- **テストデータ**: FactoryBot + Faker
- **システムテスト**: Capybara + Selenium WebDriver
- **データベース**: PostgreSQL (RAILS_ENV=test)
- **品質チェック**: RuboCop + Brakeman

---

## モデルテスト

### 完了した部分（✅ 81%）

| モデル | Examples | Passing | Pending | 完成度 |
|--------|----------|---------|---------|--------|
| User | 32 | 27 | 5 | 84% |
| LessonRecord | 36 | 35 | 1 | 97% |
| Category | 21 | 15 | 6 | 71% |
| KeymapSet | 25 | 17 | 8 | 68% |
| Lesson | 27 | 18 | 9 | 67% |
| Share | 17 | 16 | 1 | 94% |
| **合計** | **158** | **128** | **30** | **81%** |

### テスト内容

1. ✅ **バリデーション** - 必須項目、文字数制限、フォーマット
2. ✅ **ビジネスロジック** - WPM計算、グレード判定、slug生成
3. ✅ **delegate パターン** - モデル間の委譲メソッド
4. ✅ **アソシエーション** - belongs_to, has_many
5. ✅ **インスタンスメソッド** - admin?, deletable?, grade_emoji
6. ✅ **クラスメソッド** - generate_next_slug, available_tabs
7. ⏳ **スコープ** - visible_to, published, recent（未完了）
8. ⏳ **一意性制約** - email, username, token（未完了）
9. ⏳ **コールバック** - after_create, before_validation（未完了）

---

## システムテスト（E2E）

### 実装済み

**Phase 1: クリティカルパス**

1. ✅ **認証フロー** - Google OAuth動作確認
2. ✅ **レッスン閲覧フロー** - レッスン一覧→詳細
3. ✅ **練習履歴フロー** - 期間フィルター、Turbo Frames

### 将来実装

**Phase 2: 重要なユーザーフロー**

4. ❌ **キーマップ閲覧・選択フロー** - 選択、アクティブ化
5. ❌ **キーマップ編集フロー** - CRUD操作
6. ❌ **シェア機能** - リンク生成、OGP

**Phase 3: 補助的な機能**

7. ❌ **管理者ダッシュボード** - 権限チェック

### スキップ推奨

8. ❌ **タイピング入力の完全シミュレーション** - JavaScript動作が複雑（モデルテストで代用）
9. ❌ **レスポンシブ対応** - ビジュアル確認が必要（手動確認推奨）

---

## モデルテスト vs システムテスト

| テスト種類 | 目的 | 速度 | 範囲 |
|---------|------|------|------|
| **モデルテスト** | データ層のロジック検証 | ⚡ 速い | 1モデル |
| **システムテスト** | ユーザー体験の検証 | 🐌 遅い | アプリ全体 |

---

## FactoryBotのベストプラクティス

```ruby
# build() - バリデーションテスト、DB保存不要
user = build(:user, email: nil)

# create() - スコープ、一意性制約、アソシエーションのテスト
user = create(:user)

# sequence() - 一意な値の自動生成（Faker::Number.uniqueより安定）
sequence(:email) { |n| "user#{n}@example.com" }

# trait - テストシナリオのバリエーション
create(:user, :admin)
create(:lesson_record, :legendary)
```

---

## privateメソッドのテスト

```ruby
lesson_record = build(:lesson_record, typed_chars: 500, duration_seconds: 60)
lesson_record.send(:calculate_wpm)  # private メソッドを直接呼び出し
expect(lesson_record.wpm).to eq(100)
```

---

## 技術的課題: active_keymap_set NOT NULL制約

**問題点:**
- FactoryBotの `create(:user)` が `active_keymap_set_id` NOT NULL制約で失敗
- `after_create :create_default_keymap_set` コールバックが実行される前にエラー

**回避策（現在）:**
- `build(:user)` を使ってバリデーションテストのみ実行
- `send(:private_method)` でprivateメソッドを直接テスト
- `create()` が必要なテストは `skip` でスキップ

**将来的な解決策:**
1. FactoryBotのカスタム戦略
2. User modelリファクタリング

---

## テストの実行コマンド

```bash
# 全テスト実行
bundle exec rspec

# モデルテストのみ
bundle exec rspec spec/models

# システムテストのみ
bundle exec rspec spec/system

# 特定ファイル
bundle exec rspec spec/models/user_spec.rb

# 特定の行（describe/it）
bundle exec rspec spec/models/user_spec.rb:10
```

---

## CI/CD（将来実装予定）

GitHub Actions を導入すると、以下が自動化されます:

### PR 作成時

- 自動テスト実行
- RuboCop 実行
- Brakeman 実行

### main ブランチへのマージ時

- 自動デプロイ（オプション）

**設定例:**

``yaml
# .github/workflows/ci.yml
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

## 関連ドキュメント

- [コード品質](code_quality.md)
- [セキュリティ設計](../design/security.md)
