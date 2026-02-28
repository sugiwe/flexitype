# コード品質

Typnixのコード品質を維持するための指針とチェックリスト。

---

## 品質チェックツール

### RuboCop（コードスタイル）

**実行結果**: ✅ 0 offenses

```bash
bundle exec rubocop

# 自動修正
bundle exec rubocop -A
```

### Brakeman（セキュリティ静的解析）

**実行結果**: ✅ 0 warnings

```bash
bundle exec brakeman --no-pager
```

### bundler-audit（依存関係の脆弱性）

**実行結果**: ✅ 0 vulnerabilities

```bash
bundle exec bundler-audit check
```

---

## コーディング規約

### Rails way

- RESTful 設計を優先
- Railsの規約に従う（CoC: Convention over Configuration）
- 生SQLの使用を避け、Active Recordを活用

### DRY原則（Don't Repeat Yourself）

- パーシャル化（shared partial）
- delegate パターンの活用
- メソッド重複の回避

**例:**

```ruby
# app/models/lesson.rb
class Lesson < ApplicationRecord
  belongs_to :category
  delegate :premium, :requires_login, to: :category
end
```

### 命名規則

- クラス名: PascalCase（例: `LessonRecord`）
- メソッド名: snake_case（例: `calculate_wpm`）
- 定数: SCREAMING_SNAKE_CASE（例: `KEYBOARD_TYPES`）
- privateメソッドには `private` キーワードを明示

---

## ファイル構成

### Viewファースト開発

このプロジェクトでは、**Viewファースト開発アプローチ**を採用しています。

**基本方針:**
1. まず、ある程度のレイアウトを含むビューファイルを先に作成
2. ブラウザで完成版に近い形のページを見ながら開発
3. モデルやコントローラは、ビューで必要になったタイミングで実装

**メリット:**
- モチベーション向上（視覚的に確認できる）
- 完成イメージの明確化
- デザイン先行（Tailwind CSSで直接書ける）
- 手戻り削減

### ディレクトリ構成

```
app/
├── controllers/
│   ├── admin/           # 管理者機能
│   ├── my/              # 個人ページ
│   └── ...
├── models/
│   ├── concerns/        # 共通モジュール
│   └── ...
├── views/
│   ├── layouts/         # レイアウト
│   ├── shared/          # 共通パーシャル
│   ├── admin/
│   ├── my/
│   └── ...
└── javascript/
    └── controllers/     # Stimulus controllers
```

---

## Strong Parameters

**全コントローラで適切に実装**

```ruby
private

def lesson_params
  params.require(:lesson).permit(:name, :description, :category_id, items: [])
end
```

---

## セキュリティチェックリスト

### デプロイ前（必須）

- [ ] RuboCop でコード品質チェック（`bundle exec rubocop`）
- [ ] Brakeman でセキュリティチェック（`bundle exec brakeman`）
- [ ] テスト実行（`bundle exec rspec`）

### 毎月（推奨）

- [ ] `bundle exec bundler-audit check`
- [ ] `bundle update`（セキュリティパッチ）

### コード実装時

- [ ] CSRF対策: Railsのprotect_from_forgery有効
- [ ] XSS対策: 自動HTMLエスケープ有効
- [ ] SQL Injection対策: Active Record使用、生SQL禁止
- [ ] Strong Parameters: ユーザー入力を厳密にフィルタリング
- [ ] 機密情報: 環境変数またはcredentials.yml.encで管理

---

## パフォーマンス最適化

### N+1クエリ対策

```ruby
# NG
@users.each do |user|
  user.keymaps.count  # N+1クエリ発生
end

# OK
@users.includes(:keymaps).each do |user|
  user.keymaps.count  # 事前にロード済み
end
```

### インデックスの活用

```ruby
# db/migrate/XXXXXX_add_index_to_users.rb
class AddIndexToUsers < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :email, unique: true
    add_index :users, :username, unique: true
  end
end
```

---

## デバッグ

### ログ確認

```bash
# ローカル環境
tail -f log/development.log

# 本番環境
kamal app logs --follow
```

### デバッグツール

```ruby
# binding.pry（development環境のみ）
def some_method
  binding.pry  # ここで処理が止まる
  # ...
end
```

---

## コードレビューのポイント

### 実装時

- [ ] RESTful設計に従っているか
- [ ] DRY原則を守っているか
- [ ] セキュリティリスクはないか
- [ ] パフォーマンスへの影響はないか
- [ ] テストは書いたか

### PR作成時

- [ ] ブランチ名は適切か（`feature/`, `bugfix/`, `refactor/`）
- [ ] コミットメッセージは明確か
- [ ] RuboCop、Brakeman、テストが通るか
- [ ] 不要なファイルが含まれていないか（.envなど）

---

## Git運用

### ブランチ戦略

- **main**: 本番環境と同期
- **feature/**: 新機能開発
- **bugfix/**: バグ修正
- **refactor/**: リファクタリング

### コミットメッセージ

日本語で、変更内容を明確に記述：

```
Google 認証機能の実装を完了

- SessionsControllerを作成
- IDトークン検証ロジックを追加
- ログイン/ログアウト機能を実装

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

### デプロイフロー

1. ブランチ作成
2. 実装・テスト
3. リモートにプッシュ
4. PR作成
5. 人間の開発者がレビュー・マージ
6. mainブランチをpull
7. ブランチ削除

---

## 関連ドキュメント

- [テスト戦略](testing.md)
- [セキュリティ設計](../design/security.md)
- [デプロイガイド](../operations/deployment.md)
