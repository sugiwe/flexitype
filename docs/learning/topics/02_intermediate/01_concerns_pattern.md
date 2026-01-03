# Concernパターン - コードの共通化とDRY原則

## 🎯 学習目標

この教材を学ぶことで以下ができるようになります：
- [ ] Concernパターンの基本的な使い方を理解する
- [ ] コントローラー間でロジックを共通化できる
- [ ] DRY原則に則ったコードを書ける
- [ ] Rails wayなコード設計ができる

## 📚 前提知識

- Railsのコントローラーの基本（`params`、`render`、`private`メソッド）
- `ApplicationController`の継承関係
- 名前空間（`namespace`）の概念

## 📖 本編

### 概要

Flexitypeプロジェクトでは、Day 29に「未ログインユーザーの練習記録保存機能」を実装しました。この機能では、ログインユーザーと未ログインユーザーの両方が練習記録を保存できるようにする必要がありました。

しかし、実装の過程で以下の問題が発生しました：

**問題:**
- `LessonRecordsController`（公開エンドポイント）
- `My::LessonRecordsController`（認証必須エンドポイント）

この2つのコントローラーで、**練習記録を保存するロジックが完全に重複**してしまいました。

**解決策:**
`ActiveSupport::Concern`を使ってロジックを共通化し、DRY原則（Don't Repeat Yourself）に則ったコードに改善しました。

### 実装前（アンチパターン）

#### 1. `app/controllers/lesson_records_controller.rb`

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

#### 2. `app/controllers/my/lesson_records_controller.rb`

```ruby
class My::LessonRecordsController < My::ApplicationController
  def index
    # ... 省略 ...
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

  def lesson_record_params
    params.require(:lesson_record).permit(
      :lesson_id, :lesson_name, :word_count, :correct_count,
      :mistake_count, :accuracy, :duration_seconds, :typed_chars
    )
  end
end
```

**問題点:**
1. **コードの重複**: `create`アクションのロジックがほぼ同じ
2. **`lesson_record_params`メソッドの重複**: 完全に同じコード
3. **保守性の低下**: 変更時に2箇所修正する必要がある
4. **テストの重複**: 両方のコントローラーで同じテストを書く必要がある

### 実装後（ベストプラクティス）

#### 1. Concernの作成: `app/controllers/concerns/lesson_record_creation.rb`

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

#### 2. `app/controllers/lesson_records_controller.rb`（改善後）

```ruby
class LessonRecordsController < ApplicationController
  include LessonRecordCreation

  def create
    user = logged_in? ? current_user : User.find_by!(username: "guest")
    create_lesson_record_for(user)
  end
end
```

#### 3. `app/controllers/my/lesson_records_controller.rb`（改善後）

```ruby
class My::LessonRecordsController < My::ApplicationController
  include LessonRecordCreation

  def index
    # ... 省略 ...
  end

  def create
    create_lesson_record_for(current_user)
  end
end
```

### 解説

#### Concernパターンのメリット

**1. DRY原則の徹底**
- 共通ロジックが1箇所にまとまる
- 変更時の修正箇所が1箇所のみ
- コード量の削減（この例では約30行削減）

**2. テストが容易**
- Concernのみテストすれば、両方のコントローラーの動作が保証される
- テストコードの重複も削減

**3. 名前空間の分離を保ちつつ共通化**
- `LessonRecordsController`と`My::LessonRecordsController`は独立したコントローラー
- 継承ではなくミックスインで共通化（Rails way）
- それぞれのコントローラーが独自のロジックを持てる

**4. 可読性の向上**
- `create_lesson_record_for(user)`という明確なメソッド名
- 何をしているかが一目瞭然

#### Concernの基本構造

```ruby
module YourConcern
  extend ActiveSupport::Concern

  # インスタンスメソッド（通常のメソッド）
  def some_method
    # ...
  end

  private

  def private_method
    # ...
  end

  # クラスメソッド（オプション）
  class_methods do
    def some_class_method
      # ...
    end
  end

  # インクルード時に実行される処理（オプション）
  included do
    # before_action :some_method などを書ける
  end
end
```

#### Concernを使うべきケース

**適している:**
- 複数のコントローラーで同じロジックが必要
- 名前空間が異なるコントローラー間での共通化
- 特定のドメインロジック（例: 認証、ログ記録、エラーハンドリング）

**適していない:**
- 1つのコントローラーでのみ使用するメソッド（privateメソッドで十分）
- 継承で解決できる場合（例: `ApplicationController`）
- 異なるドメインのロジックを無理やり共通化しようとする場合

#### なぜ継承ではなくConcernなのか？

**継承の問題点:**
```ruby
# ❌ 継承では解決できない
class LessonRecordsController < My::LessonRecordsController
  # My::ApplicationController を継承したくないのに継承してしまう
  # 名前空間の意味がなくなる
end
```

**Concernの利点:**
```ruby
# ✅ Concernなら独立性を保てる
class LessonRecordsController < ApplicationController
  include LessonRecordCreation  # 必要なロジックだけミックスイン
end

class My::LessonRecordsController < My::ApplicationController
  include LessonRecordCreation  # 同じロジックを再利用
end
```

### 実際の変更内容（Day 29のコミット）

この改善は以下のPRで実装されました：
- **PR**: #101
- **日報**: Day 29（2025-12-29）
- **変更ファイル数**: 3ファイル
  - 新規: `app/controllers/concerns/lesson_record_creation.rb`
  - 変更: `app/controllers/lesson_records_controller.rb`
  - 変更: `app/controllers/my/lesson_records_controller.rb`

**コード削減:**
- 削除: 約30行（重複コード）
- 追加: 約20行（Concern）
- 純削減: 約10行

## 💡 まとめ

**Concernパターンの重要ポイント:**

1. **DRY原則**: コードの重複を避ける
2. **`extend ActiveSupport::Concern`**: Concernモジュールの宣言
3. **`include`でミックスイン**: コントローラーに機能を追加
4. **Rails wayな設計**: 継承ではなくミックスインで共通化
5. **配置場所**: `app/controllers/concerns/` ディレクトリ

**実践のポイント:**

- Concernの名前は明確に（例: `LessonRecordCreation`）
- メソッド名も明確に（例: `create_lesson_record_for(user)`）
- `private`メソッドはConcern内でも`private`にする
- 1つのConcernは1つの責務に集中する

## 🔗 関連教材

- [DRY原則の実践](02_dry_principle.md) - ビューの共通化
- [リファクタリングパターン](../03_advanced/01_refactoring_patterns.md) - その他の改善パターン

## 📝 演習問題

### 問題1: 基礎理解

以下のコードをConcernパターンで改善してください。

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def create
    @post = Post.new(post_params)
    if @post.save
      render json: { success: true }
    else
      render json: { success: false, errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def post_params
    params.require(:post).permit(:title, :body)
  end
end

# app/controllers/admin/posts_controller.rb
class Admin::PostsController < Admin::ApplicationController
  def create
    @post = Post.new(post_params)
    if @post.save
      render json: { success: true }
    else
      render json: { success: false, errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def post_params
    params.require(:post).permit(:title, :body)
  end
end
```

<details>
<summary>解答例を表示</summary>

```ruby
# app/controllers/concerns/post_creation.rb
module PostCreation
  extend ActiveSupport::Concern

  private

  def create_post
    @post = Post.new(post_params)
    if @post.save
      render json: { success: true }
    else
      render json: { success: false, errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def post_params
    params.require(:post).permit(:title, :body)
  end
end

# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  include PostCreation

  def create
    create_post
  end
end

# app/controllers/admin/posts_controller.rb
class Admin::PostsController < Admin::ApplicationController
  include PostCreation

  def create
    create_post
  end
end
```

</details>

### 問題2: 応用

Concernを使うべきではないケースを1つ挙げ、その理由を説明してください。

<details>
<summary>解答例を表示</summary>

**例: 1つのコントローラーでのみ使用するprivateメソッド**

```ruby
# ❌ 悪い例: Concernにする必要がない
module UserProfileFormatter
  extend ActiveSupport::Concern

  private

  def format_profile
    # UsersControllerでしか使わないロジック
  end
end

# ✅ 良い例: コントローラー内のprivateメソッドで十分
class UsersController < ApplicationController
  private

  def format_profile
    # ...
  end
end
```

**理由:**
1. 1箇所でしか使わないコードをConcernにすると、かえって複雑になる
2. コードの所在が分かりにくくなる（Concernファイルを探す必要がある）
3. 過度な抽象化は可読性を下げる

</details>

---

**作成日**: 2025-12-29
**難易度**: 🟡 中級
**学習時間の目安**: 1〜2時間
**関連Day**: Day 29
