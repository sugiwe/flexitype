# レッスンDB化と機能拡張 設計ドキュメント

**作成日**: 2025-12-20
**最終更新**: 2025-12-22
**ステータス**: Phase A 完了（Day 21）、Phase B-D は将来実装

---

## 📋 目次

1. [実装状況](#実装状況)
2. [やりたいことの整理](#やりたいことの整理)
3. [機能の依存関係と優先順位](#機能の依存関係と優先順位)
4. [設計上の重要ポイント](#設計上の重要ポイント)
5. [将来実装（Day 26以降）](#将来実装day-26以降)

---

## 実装状況

### ✅ 完了した機能（Day 21）

**Phase A: 基盤整備**
- ✅ レッスンのDB化（YAML → PostgreSQL）
- ✅ Category・Lessonモデルの設計・作成
- ✅ データ移行スクリプトの実装（Rakeタスク化）
- ✅ LessonLoaderサービスオブジェクトの削除（Rails way化）
- ✅ ユーザー用レッスンCRUD機能（`/my/lessons`）
- ✅ カテゴリー管理機能（Admin::CategoriesController）
- ✅ アーキテクチャ改善（delegate パターン、published フラグ）

詳細は [Day 21の日報](docs/daily_reports/2025-12-21.md) を参照。

### 🔜 未実装の機能（将来実装予定）

**Phase B: コア機能拡張**
- トップページのタブ化
- 成績評価システム（WPM計算、4段階評価）

**Phase C: UX向上**
- 結果シェア機能（HTML Canvas）
- 管理者レッスン増加（30+レッスン）

**Phase D: 収益化準備**
- 課金スキーム設計と実装（Stripe連携）

---

## やりたいことの整理

### 🎯 大きな方向性

1. **レッスンのDB化とユーザー作成機能**
2. **レッスン数の拡充とUI改善（タブ化）**
3. **成績評価システム**
4. **結果シェア機能（画像生成）**
5. **課金スキーム設計と実装**

### 詳細な要件

#### 1. レッスンのDB化とユーザー作成機能
- キーマップの公開と同じように、レッスンもユーザーが作って公開できるようにしたい
- 非公開レッスンも作成可能
- 現在のYAML管理からDB管理に移行
- カテゴリーも必要になる

#### 2. レッスン数の拡充とUI改善（タブ化）
- 管理者としてレッスン数をもっと増やしたい（30+レッスン）
- トップページのレッスン表示をタブ化
- タブ構成案:
  - 公式レッスン（2-3タブに分割、カテゴリーごとにグループ化）
  - 自分で作ったレッスン
  - 他のユーザーが作ったレッスン

#### 3. 成績評価システム
- レッスン終了後に成績を表示（3-4段階）
- 評価例: 「プロ級」→「上級者」→「中級者」→「初心者」（表現は要検討）
- 評価はDBに保存

#### 4. 結果シェア機能（画像生成）
- レッスン終了後に結果をシェアしたい
- 理想は画像としてシェア
- デフォルトの背景画像 + 統計数値を合成
- 画像はDB保存不要（クライアントサイドで生成）

#### 5. 課金スキーム
- 付加価値として有料ユーザーだけに開放する機能を決める
- 「無料だった機能が急に有料になる」印象を避ける
- 実装方法: まず管理者だけに実装して準備し、課金スキーム完成後に公開

---

## 機能の依存関係と優先順位

### Phase A: 基盤整備（✅ Day 21完了）

#### 1. レッスンのDB化
- **理由**: すべての機能の土台になる
- **影響範囲**: ユーザー作成レッスン、カテゴリー管理、成績評価、シェア機能すべてに必要
- **実装内容**:
  - Lesson モデル、Category モデルの作成
  - YAML データの DB 移行（Rakeタスク化）
  - LessonLoaderサービスオブジェクトの削除（Rails way化）
  - ユーザー用 CRUD 機能（`/my/lessons`）
  - カテゴリー管理機能（Admin::CategoriesController）
  - アーキテクチャ改善（delegate パターン、published フラグ）

### Phase B: コア機能拡張（将来実装）

#### 2. トップページのタブ化
- **理由**: レッスン数が増える前提で必要
- **作業量**: 小（0.5-1日）
- **内容**:
  - タブ UI の実装（公式レッスン、自作レッスン、共有レッスン）
  - カテゴリーグループ分け
  - Stimulus でタブ切り替え

#### 3. 成績評価システム
- **依存**: なし（既存の LessonRecord を活用）
- **作業量**: 小（0.5日）
- **内容**:
  - 評価ロジック（正答率 + WPM で4段階）
  - 評価表示 UI
  - DB 保存（LessonRecord に grade, wpm カラム追加）

### Phase C: UX向上（将来実装）

#### 4. 結果シェア機能（画像生成）
- **依存**: 成績評価システム（Phase B-3）
- **作業量**: 中（1日）
- **内容**:
  - HTML Canvas で画像生成（クライアントサイド）
  - 背景画像 + 統計情報の合成
  - ダウンロード機能
  - Twitter/X シェアボタン

#### 5. 管理者レッスン増加
- **依存**: なし（すでに `/my/lessons` で作成可能）
- **作業量**: 小-中（レッスン数による、0.5-1日）
- **内容**:
  - 管理者用レッスン作成画面で追加
  - カテゴリー整理
  - 30+レッスンを目指す

### Phase D: 収益化準備（将来実装）

#### 6. 課金スキーム設計と実装
- **作業量**: 大（3-5日以上）
- **内容**:
  - Stripe 連携
  - プラン設計（無料/有料の機能分け）
  - サブスクリプション管理
  - 有料機能のアクセス制御

---

## 設計上の重要ポイント

### 1. レッスンDB化の設計

#### Lesson モデル

```ruby
class Lesson < ApplicationRecord
  belongs_to :user  # NOT NULL - 公式レッスンは official@typnix.com のユーザーID
  belongs_to :category
  has_many :lesson_records, dependent: :destroy

  # カラム
  - user_id (references users, not null) # 公式レッスンは official@typnix.com のユーザーID
  - category_id (references categories, not null)
  - name (string, max: 100, not null)
  - description (text, max: 500)
  - lesson_type (string, "words" or "sentences")
  - items (jsonb, not null) # 単語/文章リスト
  - count (integer, default: 20, not null)
  - is_public (boolean, default: false, not null)
  - requires_login (boolean, default: false, not null)
  - premium (boolean, default: false, not null)
  - created_at, updated_at

  # バリデーション
  - validates :name, presence: true, length: { maximum: 100 }
  - validates :description, length: { maximum: 500 }, allow_blank: true
  - validates :lesson_type, inclusion: { in: %w[words sentences] }
  - validates :items, presence: true
  - validates :count, numericality: { greater_than: 0, less_than_or_equal_to: 100 }

  # スコープ
  - scope :official, -> { joins(:user).where(users: { admin: true }) }
  - scope :user_created, -> { joins(:user).where.not(users: { admin: true }) }
  - scope :published, -> { where(is_public: true) }
  - scope :free, -> { where(premium: false) }
  - scope :premium, -> { where(premium: true) }
end
```

**公式レッスンの判定方法:**
- 公式レッスンは `official@typnix.com` のユーザーアカウントに紐づける
- このユーザーは `ADMIN_EMAILS` に登録され、`admin?` メソッドで `true` を返す
- スコープ `.official` は `joins(:user).where(users: { admin: true })` で判定
- データ整合性のため、`user_id` は `NOT NULL` 制約あり

#### Category モデル

```ruby
class Category < ApplicationRecord
  has_many :lessons, dependent: :destroy

  # カラム
  - name (string, max: 50, not null, unique)
  - description (text, max: 200)
  - display_order (integer, default: 0, not null)
  - requires_login (boolean, default: false, not null)
  - premium (boolean, default: false, not null)
  - created_at, updated_at

  # バリデーション
  - validates :name, presence: true, length: { maximum: 50 }, uniqueness: true
  - validates :description, length: { maximum: 200 }, allow_blank: true

  # スコープ
  - scope :ordered, -> { order(display_order: :asc) }
  - scope :free, -> { where(premium: false) }
end
```

#### LessonRecord モデルの拡張

```ruby
class LessonRecord < ApplicationRecord
  belongs_to :user
  belongs_to :lesson  # 新規追加（既存のlesson_idカラムを外部キーに変更）

  # 新規追加カラム
  - lesson_id (references lessons, not null) # 既存のintegerカラムを外部キーに変更
  - grade (string, max: 20) # "プロ級", "上級者", "中級者", "初心者"
  - wpm (integer) # Words Per Minute

  # 既存カラムはそのまま
  - user_id, category, lesson_name, word_count, correct_count, mistake_count,
    accuracy, duration_seconds, completed_at
end
```

### 2. 成績評価ロジック

```ruby
# app/models/lesson_record.rb
class LessonRecord < ApplicationRecord
  # ... (既存のコード)

  before_save :calculate_grade
  before_save :calculate_wpm

  private

  def calculate_wpm
    return if duration_seconds.nil? || duration_seconds.zero?

    # WPM = (word_count / duration_seconds) * 60
    self.wpm = ((word_count.to_f / duration_seconds) * 60).round
  end

  def calculate_grade
    return if accuracy.nil? || wpm.nil?

    self.grade = if accuracy >= 95 && wpm >= 60
      "プロ級"
    elsif accuracy >= 85 && wpm >= 40
      "上級者"
    elsif accuracy >= 70 && wpm >= 20
      "中級者"
    else
      "初心者"
    end
  end
end
```

**評価基準**:
- **プロ級**: 正答率95%以上 かつ WPM 60以上
- **上級者**: 正答率85%以上 かつ WPM 40以上
- **中級者**: 正答率70%以上 かつ WPM 20以上
- **初心者**: それ以下

### 3. 課金機能の先行準備

#### User モデルに追加

```ruby
class User < ApplicationRecord
  # 既存のカラム
  # ...

  # 将来の課金対応
  - plan (string, default: "free", not null) # "free", "premium"
  - premium_until (datetime, nullable)

  # メソッド
  def premium?
    plan == "premium" && (premium_until.nil? || premium_until > Time.current)
  end

  def can_create_lesson?
    return true if admin? || premium?
    lessons.count < 2
  end

  def can_publish_lesson?
    premium?
  end
end
```

**無料/有料機能の分け方**:

| 機能 | 無料プラン | 有料プラン |
|------|-----------|-----------|
| 公式レッスン（基礎） | ✅ | ✅ |
| 公式レッスン（全カテゴリ） | ❌ | ✅ |
| キーマップ登録 | 2つまで | 5つまで |
| 練習履歴 | 50件 | 無制限 |
| 自作レッスン作成 | 2つまで（非公開のみ） | 5つまで（公開可能） |
| レッスン公開 | ❌ | ✅ |
| 統計グラフ | ❌ | ✅ |
| WPM記録 | ❌ | ✅ |

### 4. データ移行スクリプト

```ruby
# lib/tasks/migrate_lessons.rake
namespace :lessons do
  desc "Migrate lessons from YAML to database"
  task migrate_to_db: :environment do
    yaml_data = YAML.load_file(Rails.root.join("config/typing_lessons.yml"))

    # Typnix公式アカウントを取得
    official_user = User.find_by!(email: "official@typnix.com")

    yaml_data["lessons"].each do |category_key, category_data|
      # カテゴリーを作成
      category = Category.find_or_create_by!(name: category_data["category"]) do |c|
        c.description = category_data["description"]
        c.requires_login = category_data["requires_login"]
        c.premium = category_data["premium"]
      end

      # レッスンを作成
      category_data["lessons"].each do |lesson_data|
        Lesson.find_or_create_by!(
          user: official_user,  # Typnix公式アカウント
          category: category,
          name: lesson_data["name"]
        ) do |lesson|
          lesson.description = lesson_data["description"]
          lesson.lesson_type = lesson_data["type"]
          lesson.items = lesson_data["items"]
          lesson.count = lesson_data["count"]
          lesson.requires_login = category_data["requires_login"]
          lesson.premium = category_data["premium"]
          lesson.is_public = true
        end
      end
    end

    puts "Migration completed!"
  end
end
```

**事前準備:**
1. Googleアカウント `official@typnix.com` を作成
2. Google Cloud Consoleで認証を許可
3. 環境変数に追加:
   - `ADMIN_EMAILS` に `official@typnix.com` を追加
   - `ALLOWED_EMAILS` に `official@typnix.com` を追加
4. アプリケーションにログインしてUserレコードを作成
5. ユーザー名を「Typnix公式」に設定
6. 上記のRakeタスクを実行してYAMLからDBに移行

### 5. URL設計

#### 管理者用

```ruby
# config/routes.rb
namespace :admin do
  root to: "dashboard#index"
  resources :users, only: [:index, :show]
  resources :lessons  # 管理者用レッスンCRUD
  resources :categories  # カテゴリー管理
end
```

#### ユーザー用

```ruby
# 個人ページ（/my配下）
namespace :my do
  # ... (既存のルート)
  resources :lessons  # ユーザー作成レッスンCRUD
end

# 公開ページ
resources :lessons, only: [:index, :show]  # 既存のレッスン表示
```

---

## 将来実装（Day 26以降）

### 管理者レッスン増加
- 管理者用レッスン作成画面で継続的に追加
- 30+レッスンを目指す
- カテゴリー整理

### 課金スキーム設計と実装

**実装順序**:
1. Day 23 の「ユーザー作成レッスン機能」は、まず管理者のみに実装
2. 課金スキーム実装後に一般ユーザーに開放
3. これにより「急に有料化」という印象を避ける

**技術スタック**:
- Stripe（決済処理）
- Subscription モデル（サブスクリプション管理）
- Webhook 処理（支払い成功/失敗の処理）

**実装内容**:
1. Stripe 連携
2. プラン設計（無料/有料の機能分け）
3. サブスクリプション管理画面
4. 有料機能のアクセス制御
5. 支払い履歴

---

## まとめ

### ✅ 実装完了した機能（Day 21）

**Phase A: 基盤整備**
1. ✅ レッスンのDB化（YAML → PostgreSQL）
2. ✅ Category・Lessonモデルの設計・作成
3. ✅ データ移行スクリプト（Rakeタスク化）
4. ✅ LessonLoaderサービスオブジェクトの削除（Rails way化）
5. ✅ ユーザー用レッスンCRUD機能（`/my/lessons`）
6. ✅ カテゴリー管理機能（Admin::CategoriesController）
7. ✅ アーキテクチャ改善（delegate パターン、published フラグ）

### 🔜 将来実装する機能（Day 26以降）

**Phase B: コア機能拡張**
1. トップページのタブ化
2. 成績評価システム（WPM計算、4段階評価）

**Phase C: UX向上**
3. 結果シェア機能（HTML Canvas）
4. 管理者レッスン増加（30+レッスン）

**Phase D: 収益化準備**
5. 課金スキーム設計と実装（Stripe連携）

この設計により、レッスン管理の基盤が整い、将来的な機能拡張や課金スキームにもスムーズに移行できる柔軟なアーキテクチャとなっています。
