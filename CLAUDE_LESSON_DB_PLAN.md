# レッスンDB化と機能拡張計画

**作成日**: 2025-12-20
**ステータス**: 計画段階（Day 21-25 で実装予定）

---

## 📋 目次

1. [やりたいことの整理](#やりたいことの整理)
2. [機能の依存関係と優先順位](#機能の依存関係と優先順位)
3. [スケジュール案（Day 21-25）](#スケジュール案day-21-25)
4. [設計上の重要ポイント](#設計上の重要ポイント)
5. [将来実装（Day 26以降）](#将来実装day-26以降)

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

### Phase A: 基盤整備（最優先）

#### 1. レッスンのDB化
- **理由**: すべての機能の土台になる
- **影響範囲**: ユーザー作成レッスン、カテゴリー管理、成績評価、シェア機能すべてに必要
- **作業量**: 大（2-3日）
- **内容**:
  - Lesson モデル、Category モデルの作成
  - YAML データの DB 移行
  - 管理者用 CRUD 機能
  - 既存機能の動作確認

#### 2. トップページのタブ化
- **理由**: レッスン数が増える前提で必要
- **作業量**: 小（0.5-1日）
- **内容**:
  - タブ UI の実装（公式レッスン数グループ、自作レッスン、共有レッスン）
  - カテゴリー整理

### Phase B: コア機能拡張（高優先度）

#### 3. ユーザー作成レッスン機能
- **依存**: レッスンDB化（Phase A-1）
- **作業量**: 中（1-2日）
- **内容**:
  - レッスン作成 UI
  - 公開/非公開設定
  - 自分のレッスン一覧

#### 4. 成績評価システム
- **依存**: なし（既存の LessonRecord を活用）
- **作業量**: 小（0.5日）
- **内容**:
  - 評価ロジック（正答率 + 速度で3-4段階）
  - 評価表示 UI
  - DB 保存（LessonRecord に grade カラム追加）

### Phase C: UX向上（中優先度）

#### 5. 結果シェア機能（画像生成）
- **依存**: 成績評価システム（Phase B-4）
- **作業量**: 中（1日）
- **内容**:
  - HTML Canvas で画像生成（クライアントサイド）
  - 背景画像 + 統計情報の合成
  - ダウンロード機能
  - Twitter/X シェアボタン

#### 6. 管理者レッスン増加
- **依存**: レッスンDB化（Phase A-1）
- **作業量**: 小-中（レッスン数による、0.5-1日）
- **内容**:
  - 管理者用レッスン作成画面で追加
  - カテゴリー整理

### Phase D: 収益化準備（低優先度、将来実装）

#### 7. 課金スキーム設計と実装
- **作業量**: 大（3-5日以上）
- **内容**:
  - Stripe 連携
  - プラン設計（無料/有料の機能分け）
  - サブスクリプション管理
  - 有料機能のアクセス制御

---

## スケジュール案（Day 21-25）

### 🚀 Day 21（2025-12-21）: レッスンDB化 Part 1

**目標**: DB設計とモデル実装、YAML移行

**作業内容**:
1. Lesson モデル、Category モデルの設計・作成
2. マイグレーション実装
3. YAML データを DB に移行するスクリプト
4. LessonLoader を DB ベースに書き換え

**成果物**:
- Lesson, Category モデル
- データ移行完了
- 既存機能が DB ベースで動作

---

### 🚀 Day 22（2025-12-22）: レッスンDB化 Part 2 + トップページタブ化

**目標**: 管理者用CRUD + トップページ改修

**午前: 管理者用レッスン管理**
1. `/admin/lessons` 一覧ページ
2. `/admin/lessons/new` 新規作成フォーム
3. `/admin/lessons/:id/edit` 編集フォーム
4. カテゴリー管理

**午後: トップページタブ化**
1. タブ UI 実装（Stimulus）
2. カテゴリーグループ分け
3. レスポンシブ対応

**成果物**:
- 管理者がレッスンを追加・編集できる
- トップページがタブ化され見やすくなる

---

### 🚀 Day 23（2025-12-23）: ユーザー作成レッスン機能

**目標**: ユーザーが自分でレッスンを作成・公開できる

**作業内容**:
1. `/my/lessons` 一覧ページ
2. `/my/lessons/new` 新規作成フォーム
3. 公開/非公開設定
4. 他ユーザーの公開レッスン閲覧

**成果物**:
- ユーザーがレッスンを作成できる
- 公開レッスンが他ユーザーに見える
- トップページの「共有レッスン」タブで表示

---

### 🚀 Day 24（2025-12-24）: 成績評価システム + 結果シェア機能

**目標**: レッスン終了後の体験を豊かにする

**午前: 成績評価システム**
1. 評価ロジック実装（正答率 + WPM で4段階）
2. LessonRecord に grade カラム追加
3. 完了画面に評価表示

**午後: 結果シェア機能**
1. HTML Canvas で画像生成（背景 + 統計情報）
2. ダウンロードボタン
3. Twitter/X シェアボタン

**成果物**:
- レッスン終了時に「プロ級」などの評価が表示
- 結果を画像でシェアできる

---

### 🚀 Day 25（2025-12-25）: バグ修正 + 最終調整 + ドキュメント整備

**目標**: プロジェクトの完成と記録

**作業内容**:
1. バグ修正（Day 21-24 で発見した問題）
2. パフォーマンス最適化（N+1 クエリなど）
3. セキュリティチェック（Brakeman, bundler-audit）
4. 日報作成（Day 21-25 分）
5. CLAUDE.md 最終更新
6. プロジェクト完了の振り返り

**成果物**:
- 25日間プロジェクトの完成
- すべての日報とドキュメント

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

### 25日間で実装する機能（Day 21-25）
1. ✅ レッスンDB化（Day 21-22）
2. ✅ トップページタブ化（Day 22）
3. ✅ ユーザー作成レッスン（Day 23）
4. ✅ 成績評価システム（Day 24）
5. ✅ 結果シェア機能（Day 24）

### 将来実装する機能（Day 26以降）
1. 管理者レッスン増加（継続的）
2. 課金スキーム設計と実装（Day 26-30）

### 開発の流れ
- **Day 21-22**: 基盤整備（DB化、タブ化）
- **Day 23**: コア機能拡張（ユーザーレッスン）
- **Day 24**: UX向上（成績、シェア）
- **Day 25**: 仕上げ（バグ修正、ドキュメント）

この計画で進めれば、25日間で主要機能が完成し、将来的な課金スキームにもスムーズに移行できる設計になっています。
