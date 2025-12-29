# Review Test #01: Concernパターンの導入

**難易度**: 🟡 中級
**推定時間**: 30分〜1時間
**学習トピック**: [Concernパターン](../02_intermediate/01_concerns_pattern.md)

---

## 前提条件

あなたはFlexitypeプロジェクトのコードレビュアーです。
以下のPRがレビュー待ちになっています。

## PR概要

- **タイトル**: 未ログインユーザーの練習記録保存機能
- **変更ファイル数**: 4ファイル
- **目的**: ログインしていないユーザーも練習記録を保存できるようにする

## 変更内容

### 1. `app/controllers/lesson_records_controller.rb` (新規作成)

```ruby
class LessonRecordsController < ApplicationController
  def create
    user = logged_in? ? current_user : User.find_by!(username: "guest")
    @lesson_record = user.lesson_records.build(lesson_record_params)
    @lesson_record.completed_at = Time.current

    if @lesson_record.save
      render json: { success: true, message: "練習履歴を保存しました", lesson_record_id: @lesson_record.id }
    else
      render json: { success: false, errors: @lesson_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def lesson_record_params
    params.require(:lesson_record).permit(
      :lesson_id, :lesson_name, :word_count, :correct_count,
      :mistake_count, :accuracy, :duration_seconds, :typed_chars
    )
  end
end
```

### 2. `app/controllers/my/lesson_records_controller.rb` (既存)

```ruby
class My::LessonRecordsController < My::ApplicationController
  def index
    @period = params[:period] || "all"
    @filtered_records = filter_by_period(current_user.lesson_records, @period)
    @lesson_records = @filtered_records.recent.page(params[:page]).per(20)
    @total_count = @filtered_records.count
    @average_accuracy = @filtered_records.average(:accuracy)&.round(1) || 0
    @average_wpm = @filtered_records.where.not(wpm: nil).average(:wpm)&.round(1) || 0
  end

  def create
    @lesson_record = current_user.lesson_records.build(lesson_record_params)
    @lesson_record.completed_at = Time.current

    if @lesson_record.save
      render json: { success: true, message: "練習履歴を保存しました", lesson_record_id: @lesson_record.id }
    else
      render json: { success: false, errors: @lesson_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def filter_by_period(records, period)
    case period
    when "week"
      records.where("completed_at >= ?", 1.week.ago)
    when "month"
      records.where("completed_at >= ?", 1.month.ago)
    else
      records
    end
  end

  def lesson_record_params
    params.require(:lesson_record).permit(
      :lesson_id, :lesson_name, :word_count, :correct_count,
      :mistake_count, :accuracy, :duration_seconds, :typed_chars
    )
  end
end
```

### 3. `config/routes.rb` (一部抜粋)

```ruby
# 追加部分
resources :lesson_records, only: [ :create ]  # POST /lesson_records

namespace :my do
  resources :history, only: [ :index, :create ], controller: "lesson_records"
end
```

### 4. `db/migrate/20251228222643_create_guest_user.rb` (新規)

```ruby
class CreateGuestUser < ActiveRecord::Migration[8.1]
  def up
    User.create!(
      google_uid: "guest-system-user",
      email: "guest@system.local",
      name: "未ログインユーザー",
      username: "guest"
    )
  end

  def down
    User.find_by(username: "guest")&.destroy
  end
end
```

---

## レビュー課題

### Q1. コードの重複（初級）🟢

このPRには明らかなコードの重複があります。

1. どこが重複していますか？具体的に指摘してください。
2. コード量として何行くらい重複していますか？
3. この重複はなぜ問題なのでしょうか？（メンテナンス性の観点から2つ以上）

**回答時間の目安**: 5分

<details>
<summary>解答を表示</summary>

### A1. コードの重複

**1. 重複箇所:**

`LessonRecordsController`と`My::LessonRecordsController`の以下の部分が重複：

```ruby
# createアクションのロジック（一部異なる）
@lesson_record = user.lesson_records.build(lesson_record_params)
@lesson_record.completed_at = Time.current

if @lesson_record.save
  render json: { success: true, message: "練習履歴を保存しました", lesson_record_id: @lesson_record.id }
else
  render json: { success: false, errors: @lesson_record.errors.full_messages }, status: :unprocessable_entity
end
```

```ruby
# lesson_record_paramsメソッド（完全に同じ）
def lesson_record_params
  params.require(:lesson_record).permit(
    :lesson_id, :lesson_name, :word_count, :correct_count,
    :mistake_count, :accuracy, :duration_seconds, :typed_chars
  )
end
```

**2. コード量:**
- `create`アクションのロジック: 約8行
- `lesson_record_params`メソッド: 約7行
- **合計**: 約15行 × 2箇所 = **約30行の重複**

**3. 問題点:**

**メンテナンス性の観点:**
1. **変更時の修正箇所が2倍**: パラメータを追加する場合、両方のコントローラーを修正する必要がある
2. **バグの混入リスク**: 片方だけ修正して、もう片方を修正し忘れる可能性がある
3. **テストコードの重複**: 両方のコントローラーで同じテストを書く必要がある
4. **DRY原則違反**: Don't Repeat Yourself（同じことを繰り返すな）という原則に反する
5. **可読性の低下**: コードベースが肥大化し、どこに何が書いてあるか分かりにくくなる

</details>

---

### Q2. Rails wayな改善（中級）🟡

このコードをRails wayに則って改善する場合、どのようなパターンを使いますか？

1. パターン名を答えてください
2. 具体的なファイル構成（ファイル名とディレクトリ）を示してください
3. そのパターンを使う主なメリットを3つ挙げてください

**回答時間の目安**: 10分

<details>
<summary>解答を表示</summary>

### A2. Rails wayな改善

**1. パターン名:**

**Concernパターン**（`ActiveSupport::Concern`を使用）

**2. ファイル構成:**

```
app/
└── controllers/
    ├── concerns/
    │   └── lesson_record_creation.rb  # ← 新規作成
    ├── lesson_records_controller.rb
    └── my/
        └── lesson_records_controller.rb
```

**ファイル名**: `app/controllers/concerns/lesson_record_creation.rb`

**3. メリット:**

1. **DRY原則の徹底**
   - 共通ロジックが1箇所にまとまる
   - 変更時の修正箇所が1箇所のみ
   - コード量の削減（約30行削減）

2. **テストが容易**
   - Concernのみテストすれば、両方のコントローラーの動作が保証される
   - テストコードの重複も削減
   - テストの保守性が向上

3. **名前空間の分離を保ちつつ共通化**
   - `LessonRecordsController`と`My::LessonRecordsController`は独立したコントローラー
   - 継承ではなくミックスインで共通化（Rails way）
   - それぞれのコントローラーが独自のロジックを持てる

</details>

---

### Q3. 具体的な実装（中級〜上級）🟡🔴

Q2で答えたパターンを使って、実際にコードを書いてください。

1. Concernファイルの実装を書いてください
2. `LessonRecordsController`の改善後のコードを書いてください
3. `My::LessonRecordsController`の改善後のコードを書いてください

**回答時間の目安**: 15分

<details>
<summary>解答を表示</summary>

### A3. 具体的な実装

**1. Concernファイル: `app/controllers/concerns/lesson_record_creation.rb`**

```ruby
module LessonRecordCreation
  extend ActiveSupport::Concern

  private

  def create_lesson_record_for(user)
    @lesson_record = user.lesson_records.build(lesson_record_params)
    @lesson_record.completed_at = Time.current

    if @lesson_record.save
      render json: { success: true, message: "練習履歴を保存しました", lesson_record_id: @lesson_record.id }
    else
      render json: { success: false, errors: @lesson_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def lesson_record_params
    params.require(:lesson_record).permit(
      :lesson_id, :lesson_name, :word_count, :correct_count,
      :mistake_count, :accuracy, :duration_seconds, :typed_chars
    )
  end
end
```

**ポイント:**
- `extend ActiveSupport::Concern` でConcernモジュールを宣言
- `create_lesson_record_for(user)` という明確なメソッド名
- `private`メソッドとして定義（外部から呼ばれることを想定していない）

**2. 改善後: `app/controllers/lesson_records_controller.rb`**

```ruby
class LessonRecordsController < ApplicationController
  include LessonRecordCreation

  def create
    user = logged_in? ? current_user : User.find_by!(username: "guest")
    create_lesson_record_for(user)
  end
end
```

**ポイント:**
- `include LessonRecordCreation` でConcernをミックスイン
- `create`アクションは3行のシンプルなコードに
- ユーザー判定のロジックはこのコントローラーに残る（公開エンドポイント特有のロジック）

**3. 改善後: `app/controllers/my/lesson_records_controller.rb`**

```ruby
class My::LessonRecordsController < My::ApplicationController
  include LessonRecordCreation

  def index
    @period = params[:period] || "all"
    @filtered_records = filter_by_period(current_user.lesson_records, @period)
    @lesson_records = @filtered_records.recent.page(params[:page]).per(20)
    @total_count = @filtered_records.count
    @average_accuracy = @filtered_records.average(:accuracy)&.round(1) || 0
    @average_wpm = @filtered_records.where.not(wpm: nil).average(:wpm)&.round(1) || 0
  end

  def create
    create_lesson_record_for(current_user)
  end

  private

  def filter_by_period(records, period)
    case period
    when "week"
      records.where("completed_at >= ?", 1.week.ago)
    when "month"
      records.where("completed_at >= ?", 1.month.ago)
    else
      records
    end
  end
end
```

**ポイント:**
- `include LessonRecordCreation` でConcernをミックスイン
- `create`アクションは1行に（`current_user`を渡すだけ）
- `index`アクションや`filter_by_period`メソッドはこのコントローラー固有のロジックなので残す

**コード削減効果:**
- 削除: 約30行（重複コード）
- 追加: 約20行（Concern）
- **純削減: 約10行**

</details>

---

### Q4. 設計の妥当性（上級）🔴

なぜ単純にprivateメソッドを抽出するのではなく、Concernパターンを使うべきなのでしょうか？
また、継承で解決しようとした場合、どのような問題が発生しますか？

**回答時間の目安**: 10分

<details>
<summary>解答を表示</summary>

### A4. 設計の妥当性

#### なぜConcernパターンを使うべきか？

**1. 名前空間が異なるコントローラー間での共通化**

`LessonRecordsController`と`My::LessonRecordsController`は異なる名前空間にあります。
- `LessonRecordsController` → `ApplicationController`を継承
- `My::LessonRecordsController` → `My::ApplicationController`を継承

単純なprivateメソッドでは、この2つのコントローラー間でロジックを共有できません。

**2. 継承の問題点**

仮に継承で解決しようとした場合：

```ruby
# ❌ 悪い例: 継承では解決できない
class LessonRecordsController < My::LessonRecordsController
  # ...
end
```

**問題点:**
1. **不適切な継承関係**: `My::ApplicationController`も継承してしまう
2. **名前空間の意味がなくなる**: `/my`配下は認証必須だが、`LessonRecordsController`は公開エンドポイント
3. **`My::ApplicationController`のbefore_actionが適用される**: 認証チェックなどが不適切に実行される
4. **Railsの規約に反する**: 名前空間を跨いだ継承はRails wayではない

**3. Concernの利点**

```ruby
# ✅ 良い例: Concernなら独立性を保てる
class LessonRecordsController < ApplicationController
  include LessonRecordCreation  # 必要なロジックだけミックスイン
end

class My::LessonRecordsController < My::ApplicationController
  include LessonRecordCreation  # 同じロジックを再利用
end
```

**利点:**
1. **継承関係を保ったまま共通化**: それぞれの親クラスを継承し続けられる
2. **必要な機能だけミックスイン**: 認証ロジックなどは混入しない
3. **独立性の維持**: 両コントローラーが独自のロジックを持てる
4. **Rails wayな設計**: モジュールによる機能の分離と再利用

#### まとめ

Concernパターンは、**異なる名前空間のコントローラー間でロジックを共有する際の標準的な手法**です。

単純なprivateメソッドや継承では解決できない「名前空間の壁」を、Concernなら適切に乗り越えられます。

</details>

---

## 総合評価

### 基準

- **Q1を正解**: Concernパターンの必要性を理解している
- **Q2を正解**: Rails wayな設計パターンを知っている
- **Q3を正解**: 実装レベルでConcernを使いこなせる
- **Q4を正解**: アーキテクチャレベルで設計の妥当性を判断できる

### 次のステップ

- **Q1のみ正解**: [Concernパターンの教材](../02_intermediate/01_concerns_pattern.md)を再度読んで理解を深める
- **Q1-Q2正解**: 実際にコードを書いて動作確認してみる
- **Q1-Q3正解**: 他のConcernの使用例を探してみる（例: `Authentication`, `ErrorHandling`）
- **全問正解**: 次のレビューテストに進む

## 参考資料

- [Concernパターンの教材](../02_intermediate/01_concerns_pattern.md)
- [Rails公式ガイド - Concerns](https://guides.rubyonrails.org/routing.html#controller-namespaces-and-routing)
- Day 29の日報: `docs/daily_reports/2025-12-29.md`
- 実際のPR: #101

---

**作成日**: 2025-12-29
**難易度**: 🟡 中級
**推定時間**: 30分〜1時間
