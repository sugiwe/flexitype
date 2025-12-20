# 名前規約の包括的分析と改善提案

**作成日**: 2025-12-20
**目的**: `practice`/`lesson`/`session` の名前規約を整理し、統一方針を決定する

---

## 📋 目次

1. [現状の問題点](#現状の問題点)
2. [現在の使用状況](#現在の使用状況)
3. [メリット・デメリット比較](#メリット・デメリット比較)
4. [推奨方針](#推奨方針)
5. [移行計画（lessonに統一する場合）](#移行計画lessonに統一する場合)
6. [移行しない場合の対策](#移行しない場合の対策)

---

## 現状の問題点

### 1. **session の文脈混同**
- **typing_sessions** (練習記録) と **login session** (ログインセッション) が混同される
- Rails の標準的な session (ログイン状態) と名前が衝突
- `SessionsController` は認証用、`TypingSession` は練習記録用と、同じ単語が異なる意味で使われている

### 2. **practice と lesson の使い分けの曖昧さ**
- **URL・コントローラ**: `PracticesController`, `/practices/:id`
- **データ・サービス**: `LessonLoader`, `lesson_info`, `lesson_name`
- **UI表示**: 日本語で「レッスン」と表示
- **結果**: コード内で `practice` と `lesson` が混在し、どちらを使うべきか迷う

### 3. **日本語UIとの不一致**
- UIでは「レッスン」という言葉を使っているのに、内部実装は `practice`
- 「練習（practice）」は動詞的、「レッスン（lesson）」は名詞的で、リソース名としては `lesson` の方が自然

---

## 現在の使用状況

### データベース（schema.rb）

```ruby
create_table "typing_sessions" do |t|
  t.string "category"
  t.string "lesson_id"        # ← "lesson" を使用
  t.string "lesson_name"      # ← "lesson" を使用
  # ...
end
```

**特徴**:
- テーブル名は `typing_sessions`
- カラム名は `lesson_id`, `lesson_name` を使用
- **すでにDB内で `lesson` を使っている**

### モデル

#### TypingSession (app/models/typing_session.rb)
```ruby
class TypingSession < ApplicationRecord
  belongs_to :user
  # カラム: lesson_id, lesson_name など
end
```

**特徴**:
- モデル名は `TypingSession` (認証の session と混同の可能性)
- カラム名は `lesson_id`, `lesson_name`

#### LessonLoader (app/services/lesson_loader.rb)
```ruby
class LessonLoader
  # メソッド名に "lesson" を使用
  def self.find_lesson(id)
  def self.get_lesson_info(id)
  def self.get_practice_items(id)  # ← ここだけ "practice"
  # ...
end
```

**特徴**:
- サービス名は `LessonLoader`
- メソッド名はほぼ `lesson_*` だが、`get_practice_items` だけ `practice`

### コントローラ

#### PracticesController (app/controllers/practices_controller.rb)
```ruby
class PracticesController < ApplicationController
  def show
    lesson_id = params[:id]  # ← 内部変数は "lesson"
    @lesson_info = LessonLoader.get_lesson_info(lesson_id)
    @words = LessonLoader.get_practice_items(lesson_id)
    # ...
  end
end
```

**特徴**:
- コントローラ名は `PracticesController`
- アクション名は `show`（標準的なRESTful）
- **内部変数は `lesson_id`, `@lesson_info` を使用**

#### SessionsController (app/controllers/sessions_controller.rb)
```ruby
class SessionsController < ApplicationController
  def create  # ログイン
  def destroy # ログアウト
end
```

**特徴**:
- **認証用のコントローラ**（ログイン・ログアウト）
- `TypingSession` とは全く別の文脈で `session` を使用

### ルーティング (config/routes.rb)

```ruby
resources :practices, only: [:show]  # /practices/:id
```

**特徴**:
- URL: `/practices/:id`
- リソース名: `practices`

### View (app/views/practices/show.html.slim)

```slim
h2.text-3xl.font-bold = @lesson_info[:lesson_name]
p.text-sm = @lesson_info[:category_name]
```

**特徴**:
- ディレクトリ名: `app/views/practices/`
- **表示内容は `@lesson_info[:lesson_name]`** (lesson を使用)

### JavaScript (app/javascript/controllers/typing_controller.js)

```javascript
static values = {
  words: Array,
  currentWord: Number,
  keymaps: Object,
  lessonInfo: Object,  // ← "lesson" を使用
  loggedIn: Boolean
}
```

**特徴**:
- データ値名は `lessonInfo`（lesson を使用）

### YAMLデータ (config/typing_lessons.yml)

```yaml
lessons:  # ← ファイル名も "lessons"
  basic:
    category: "基礎練習"
    lessons:  # ← キーも "lessons"
      - id: 1
        name: "ホームポジション"
```

**特徴**:
- ファイル名: `typing_lessons.yml`
- キー名: `lessons`

---

## 使用箇所の整理

### "practice" を使っている箇所

| 種類 | ファイル | 内容 |
|------|---------|------|
| **コントローラ** | `app/controllers/practices_controller.rb` | クラス名 `PracticesController` |
| **ビュー** | `app/views/practices/` | ディレクトリ名 |
| **ルーティング** | `config/routes.rb` | `resources :practices` |
| **サービス** | `app/services/lesson_loader.rb` | メソッド名 `get_practice_items` |
| **ヘルパー** | `app/helpers/practice_helper.rb` | ファイル名 |

### "lesson" を使っている箇所

| 種類 | ファイル | 内容 |
|------|---------|------|
| **DB** | `db/schema.rb` | `typing_sessions` の `lesson_id`, `lesson_name` カラム |
| **モデル** | `app/models/typing_session.rb` | カラム名 `lesson_id`, `lesson_name` |
| **サービス** | `app/services/lesson_loader.rb` | クラス名、メソッド名 `find_lesson`, `get_lesson_info` |
| **YAML** | `config/typing_lessons.yml` | ファイル名、キー名 `lessons` |
| **JavaScript** | `app/javascript/controllers/typing_controller.js` | `lessonInfo` データ値 |
| **View** | `app/views/practices/show.html.slim` | `@lesson_info[:lesson_name]` |
| **コントローラ** | `app/controllers/practices_controller.rb` | 変数名 `lesson_id`, `@lesson_info` |

### "session" を使っている箇所

| 種類 | ファイル | 内容 | 文脈 |
|------|---------|------|------|
| **DB** | `db/schema.rb` | `typing_sessions` テーブル | **練習記録** |
| **モデル** | `app/models/typing_session.rb` | クラス名 `TypingSession` | **練習記録** |
| **マイグレーション** | `db/migrate/20251215205502_create_typing_sessions.rb` | ファイル名 | **練習記録** |
| **コントローラ** | `app/controllers/sessions_controller.rb` | クラス名 `SessionsController` | **認証** |
| **ルーティング** | `config/routes.rb` | `post "/auth/google", to: "sessions#create"` | **認証** |
| **Rails標準** | `session[:user_id]` | ログイン状態管理 | **認証** |

---

## メリット・デメリット比較

### A案: 現状維持（practice のまま）

#### メリット

1. **変更コストゼロ**
   - コード変更なし、リスクなし、テスト不要
   - 開発時間を他の機能に充てられる

2. **Rails の慣習に従っている**
   - コントローラ名は複数形 (`PracticesController`)、モデル名は単数形 (`TypingSession`) という標準的な命名
   - URL も RESTful (`/practices/:id`)

3. **URL の安定性**
   - ユーザーがブックマークしている可能性のある `/practices/:id` を変更しなくて済む
   - Google Analytics のデータも連続性が保たれる

4. **動詞的なニュアンス**
   - 「練習する（practice）」という動作を表すため、ユーザーのアクションを表現している

#### デメリット

1. **内部での混乱**
   - コントローラは `PracticesController`、変数は `lesson_id`, `@lesson_info`
   - 新しいコードを書くたびに「どっちを使うべき？」と迷う

2. **DB との不一致**
   - DB のカラム名は `lesson_id`, `lesson_name`
   - モデルとDB の命名に一貫性がない

3. **日本語 UI との不一致**
   - UI は「レッスン」と表示
   - コード内部は `practice`
   - 翻訳・多言語化の際に混乱する可能性

4. **session 問題は未解決**
   - `TypingSession` と `session[:user_id]` の混同は残る

5. **将来の拡張性**
   - レッスンの公開・共有機能を作る場合、`/lessons` という URL の方が自然
   - `PublicLessonsController` のような名前の方が直感的

---

### B案: lesson に統一

#### メリット

1. **完全な一貫性**
   - DB、モデル、コントローラ、View、JavaScript すべてで `lesson` を使用
   - 新しいコードを書く際に迷わない

2. **DB との整合性**
   - DB のカラム名 (`lesson_id`, `lesson_name`) とコードが一致
   - `TypingSession` の `lesson_id` と `LessonsController` で統一感がある

3. **日本語 UI との一致**
   - 「レッスン」= `lesson`
   - コードと UI の対応が明確

4. **名詞的で自然**
   - リソース名としては「練習（practice）」より「レッスン（lesson）」の方が自然
   - 「レッスンを選ぶ」「レッスンを受ける」という表現が自然

5. **将来の拡張性**
   - レッスンの公開・共有: `/lessons/:id`, `PublicLessonsController`
   - カスタムレッスン: `/my/lessons`, `My::LessonsController`
   - URL 構造が直感的で拡張しやすい

6. **session 問題の部分的解決**
   - `TypingSession` を `LessonRecord` や `LessonResult` にリネームすることで、認証の `session` との混同を回避できる

#### デメリット

1. **変更コストが高い**
   - コントローラ、ビュー、ルーティング、テストなど多数のファイルを変更
   - 開発時間: 2〜4 時間程度（テスト含む）

2. **URL 変更のリスク**
   - `/practices/:id` → `/lessons/:id`
   - **影響**: 現在は公開直後で、外部リンクやブックマークはほぼゼロ
   - **リダイレクト対応が必要**（301 リダイレクトで旧 URL から新 URL へ）

3. **Git 履歴の複雑化**
   - ファイル名変更、クラス名変更により、Git blame が追いにくくなる
   - **対策**: リネームコミットを明確に記録、`git log --follow` を使用

4. **テストの更新**
   - コントローラテスト、ルーティングテスト、統合テストなどを更新
   - **現状**: テストコードがほとんどない（今後追加予定）
   - **影響**: 現時点では軽微

---

## session 問題の詳細分析

### 現状の混乱ポイント

```ruby
# 認証用 session（Rails 標準）
session[:user_id] = user.id

# 認証用コントローラ
class SessionsController < ApplicationController
  def create  # ログイン
  def destroy # ログアウト
end

# 練習記録モデル
class TypingSession < ApplicationRecord
  # ...
end

# 練習記録テーブル
create_table "typing_sessions" do |t|
  # ...
end
```

### 混同の具体例

1. **コードレビュー時**
   - 「session を更新する」と言われたとき、ログイン session か TypingSession か不明
   - 「SessionsController を見て」と言われたとき、認証か練習記録か混乱

2. **新しい開発者が参加したとき**
   - `TypingSession` というモデル名から、Rails の `session` と関連があると誤解する可能性

3. **エラーメッセージ**
   - 「session の保存に失敗しました」というエラーが出たとき、どちらの session か分からない

### 解決策の比較

| 解決策 | 変更内容 | メリット | デメリット |
|--------|---------|---------|----------|
| **A案: 現状維持** | 変更なし | コストゼロ | 混乱が残る |
| **B案: TypingSession → LessonRecord** | モデル名・テーブル名を変更 | 混同を完全に回避 | DB マイグレーションが必要 |
| **C案: TypingSession → LessonResult** | モデル名・テーブル名を変更 | 「結果」という意味が明確 | DB マイグレーションが必要 |
| **D案: TypingSession → Practice** | モデル名・テーブル名を変更 | `PracticesController` と統一 | `practice` を使い続けることになる |

**推奨**: `LessonRecord` または `LessonResult` へのリネームが最も明確

---

## 推奨方針

### 🎯 **推奨: B案（lesson に統一）+ session 問題の解決**

#### 理由

1. **現在のタイミングが最適**
   - 公開直後で外部リンクがほぼゼロ
   - ユーザー数が少なく、URL 変更の影響が最小限
   - 「後から変えるのはもっと大変」という懸念は正しい

2. **すでに内部で lesson を使っている**
   - DB カラム名: `lesson_id`, `lesson_name`
   - サービス: `LessonLoader`
   - JavaScript: `lessonInfo`
   - **実質的にすでに `lesson` ベース**

3. **将来の拡張性**
   - レッスンの公開・共有機能（`/lessons/:id`, `PublicLessonsController`）
   - カスタムレッスン（`/my/lessons`）
   - DB 化した際の整合性

4. **session 問題も同時に解決**
   - `TypingSession` → `LessonRecord` にリネーム
   - 認証の `session` との混同を完全に回避

5. **一貫性による長期的なメリット**
   - 新しいコードを書く際に迷わない
   - 新しい開発者がコードを理解しやすい
   - UI とコードの対応が明確

---

## 移行計画（lesson に統一する場合）

### フェーズ1: 準備（5分）

1. **新しいブランチを作成**
   ```bash
   git checkout -b refactor/rename-practice-to-lesson
   ```

2. **現状のコミット**
   - 作業中の変更があればコミット

### フェーズ2: DB リネーム（typing_sessions → lesson_records）（30分）

#### ステップ1: マイグレーションファイル作成

```bash
rails g migration RenameTypingSessionsToLessonRecords
```

```ruby
# db/migrate/YYYYMMDDHHMMSS_rename_typing_sessions_to_lesson_records.rb
class RenameTypingSessionsToLessonRecords < ActiveRecord::Migration[8.1]
  def change
    rename_table :typing_sessions, :lesson_records
  end
end
```

#### ステップ2: モデル名変更

```bash
# ファイル名変更
mv app/models/typing_session.rb app/models/lesson_record.rb
```

```ruby
# app/models/lesson_record.rb
class LessonRecord < ApplicationRecord
  belongs_to :user

  # バリデーション
  validates :word_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :correct_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :mistake_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :accuracy, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :duration_seconds, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  after_create :cleanup_old_records

  scope :recent, -> { order(completed_at: :desc) }

  private

  def cleanup_old_records
    user.cleanup_old_lesson_records
  end
end
```

#### ステップ3: User モデルの関連付け変更

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_many :keymaps, dependent: :destroy
  has_many :keymap_sets, dependent: :destroy
  has_many :lesson_records, dependent: :destroy  # ← 変更

  # ...

  def cleanup_old_lesson_records  # ← メソッド名変更
    return unless lesson_records.count > history_limit
    excess_count = lesson_records.count - history_limit
    lesson_records.order(completed_at: :asc).limit(excess_count).destroy_all
  end
end
```

#### ステップ4: マイグレーション実行

```bash
rails db:migrate
```

### フェーズ3: コントローラ・ビュー・ルーティングのリネーム（practices → lessons）（45分）

#### ステップ1: コントローラファイルのリネーム

```bash
mv app/controllers/practices_controller.rb app/controllers/lessons_controller.rb
mv app/helpers/practice_helper.rb app/helpers/lesson_helper.rb
```

```ruby
# app/controllers/lessons_controller.rb
class LessonsController < ApplicationController
  def show
    # URLパラメータから数値IDを取得
    lesson_id = params[:id]

    # レッスン情報を取得
    @lesson_info = LessonLoader.get_lesson_info(lesson_id)

    # 練習用の単語/文章を取得
    @words = LessonLoader.get_practice_items(lesson_id)

    # レッスンが見つからない場合は404
    if @lesson_info.nil? || @words.empty?
      redirect_to root_path, alert: "レッスンが見つかりませんでした。"
      return
    end

    # キーマップを読み込む（ユーザーのキーマップまたはデフォルト）
    user_id = logged_in? ? current_user.id : nil
    @keymaps = Keymap.all_layers_for_user_or_default(user_id)
  end
end
```

#### ステップ2: ビューディレクトリのリネーム

```bash
mv app/views/practices app/views/lessons
```

#### ステップ3: ルーティング変更 + リダイレクト設定

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # ...

  # Public pages
  root "home#index"
  resources :lessons, only: [:show]  # ← 変更

  # 旧URLからのリダイレクト（301 Moved Permanently）
  get "/practices/:id", to: redirect("/lessons/%{id}", status: 301)

  # ...
end
```

**重要**: 旧 URL (`/practices/:id`) から新 URL (`/lessons/:id`) へ 301 リダイレクトを設定

#### ステップ4: home#index のリンク修正

```slim
# app/views/home/index.html.slim
# 変更前
= link_to practice_path(id: lesson['id']), class: "..." do

# 変更後
= link_to lesson_path(id: lesson['id']), class: "..." do
```

### フェーズ4: My::HistoryController の修正（30分）

#### ステップ1: コントローラの修正

```ruby
# app/controllers/my/history_controller.rb
class My::HistoryController < My::ApplicationController
  def index
    @lesson_records = current_user.lesson_records
                                  .recent
                                  .page(params[:page])
                                  .per(20)

    # ミニ統計
    @total_count = current_user.lesson_records.count
    @average_accuracy = current_user.lesson_records.average(:accuracy)&.round(1) || 0
  end

  def create
    @lesson_record = current_user.lesson_records.build(lesson_record_params)

    if @lesson_record.save
      render json: { success: true }, status: :created
    else
      render json: { error: @lesson_record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def lesson_record_params
    params.require(:lesson_record).permit(
      :category,
      :lesson_id,
      :lesson_name,
      :word_count,
      :correct_count,
      :mistake_count,
      :accuracy,
      :duration_seconds,
      :completed_at
    )
  end
end
```

#### ステップ2: ビューの修正

```slim
# app/views/my/history/index.html.slim
# @typing_sessions → @lesson_records に置き換え
```

### フェーズ5: JavaScript の修正（15分）

#### typing_controller.js の修正

```javascript
// app/javascript/controllers/typing_controller.js
async saveSession() {
  // ...

  const response = await fetch('/my/history', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken
    },
    body: JSON.stringify({
      lesson_record: {  // ← 変更（typing_session → lesson_record）
        category: this.lessonInfoValue.category_name,
        lesson_id: this.lessonInfoValue.id.toString(),
        lesson_name: this.lessonInfoValue.lesson_name,
        word_count: this.wordsValue.length,
        correct_count: this.wordsValue.length,
        mistake_count: this.mistakeCount,
        accuracy: accuracy,
        duration_seconds: durationSeconds,
        completed_at: new Date().toISOString()
      }
    })
  })

  // ...
}
```

### フェーズ6: Admin ダッシュボードの修正（15分）

```ruby
# app/controllers/admin/dashboard_controller.rb
def index
  @total_users = User.count
  @total_lesson_records = LessonRecord.count  # ← 変更
  @total_keymaps = KeymapSet.count
  @total_lessons = LessonLoader.all_lessons_flat.count

  @recent_users = User.order(created_at: :desc).limit(10).includes(:lesson_records, :keymap_sets)
  # ...
end
```

```slim
# app/views/admin/dashboard/index.html.slim
# TypingSession → LessonRecord に置き換え
```

### フェーズ7: 動作確認（30分）

1. **ローカル環境で動作確認**
   ```bash
   rails db:migrate
   rails s
   ```

2. **確認項目**
   - [ ] トップページのレッスン一覧が表示される
   - [ ] レッスンをクリックすると `/lessons/:id` に遷移
   - [ ] 旧 URL `/practices/:id` にアクセスすると `/lessons/:id` にリダイレクト
   - [ ] タイピング練習が正常に動作
   - [ ] セッション完了後、履歴が保存される
   - [ ] `/my/history` で履歴が表示される
   - [ ] 管理者ダッシュボードで統計が表示される

3. **Rubocop & Brakeman**
   ```bash
   bundle exec rubocop
   bundle exec brakeman --no-pager
   ```

### フェーズ8: コミット・デプロイ（15分）

```bash
# コミット
git add .
git commit -m "practice/session → lesson/lesson_record に統一

- TypingSession → LessonRecord にリネーム（DB・モデル）
- PracticesController → LessonsController にリネーム
- /practices/:id → /lessons/:id に変更（301リダイレクト設定）
- 認証のsessionとの混同を回避
- DB、モデル、コントローラ、View、JavaScriptすべてで統一

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# リモートプッシュ前のチェック
bundle exec rubocop
bundle exec brakeman --no-pager

# プッシュ
git push -u origin refactor/rename-practice-to-lesson

# PR作成
gh pr create --title "practice/session → lesson/lesson_record に統一" --body "..."

# マージ後、本番デプロイ
git checkout main
git pull
kamal deploy
```

---

## 移行しない場合の対策

もし **A案（現状維持）** を選択する場合、以下の対策で混乱を最小化できます。

### 1. コードコメントで明記

```ruby
# app/controllers/practices_controller.rb
# NOTE: コントローラ名は "Practices" だが、内部では "lesson" という用語を使用
# UI では「レッスン」と表示しており、将来的に統一する可能性がある
class PracticesController < ApplicationController
  # ...
end
```

### 2. 用語集を CLAUDE.md に追加

```markdown
## 用語集

- **practice**: URL・コントローラレベルでの名称（`/practices/:id`, `PracticesController`）
- **lesson**: データ・UI レベルでの名称（`lesson_id`, `@lesson_info`, 「レッスン」）
- **session**: 2つの文脈で使用
  - `TypingSession`: 練習記録モデル（`typing_sessions` テーブル）
  - `session[:user_id]`: Rails 標準のログインセッション
```

### 3. 新しいコードを書く際のルール

- **コントローラ・ルーティング**: `practice` を使う
- **モデル・DB・データ**: `lesson` を使う
- **UI 表示**: 「レッスン」（lesson）

---

## まとめ

### 結論: **B案（lesson に統一）を強く推奨**

#### 理由

1. **今が最適なタイミング**
   - 公開直後、外部リンクがほぼゼロ
   - ユーザー数が少なく、影響が最小限

2. **すでに内部で lesson を使っている**
   - DB カラム、サービス、JavaScript など
   - 統一することで一貫性が向上

3. **session 問題も同時に解決**
   - `TypingSession` → `LessonRecord` で認証の `session` との混同を回避

4. **将来の拡張性**
   - レッスンの公開・共有、カスタムレッスンなど

5. **長期的なメリット**
   - コードの可読性・保守性が向上
   - 新しい開発者がコードを理解しやすい

#### 変更コスト

- **開発時間**: 2〜4時間程度（テスト含む）
- **リスク**: 低（301リダイレクトで旧URLに対応）
- **影響範囲**: コントローラ、ビュー、ルーティング、JavaScript、管理画面

#### 次のステップ

1. この分析を確認
2. B案で進めることを決定
3. [移行計画](#移行計画lessonに統一する場合) に従って実装
4. デプロイ後、動作確認

---

**作成者**: Claude Code
**レビュー**: 開発者
