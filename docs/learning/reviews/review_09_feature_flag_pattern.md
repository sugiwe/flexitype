# Review Test #09: フィーチャーフラグパターン

**難易度**: 🟡 中級
**推定時間**: 30分〜1時間
**学習トピック**: [フィーチャーフラグパターン](../topics/03_advanced/09_feature_flag_pattern.md)

---

## 前提条件

あなたはFlexitypeプロジェクトのコードレビュアーです。
以下のPRがレビュー待ちになっています。

## PR概要

- **タイトル**: ALLOWED_EMAILSのDB化とフィーチャーフラグパターン実装
- **変更ファイル数**: 14ファイル
- **追加行数**: 1,001行
- **目的**: ログイン制限機能にフィーチャーフラグパターンを導入し、将来的な削除容易性を確保する

## 変更内容

### 1. `config/initializers/authentication.rb` (新規作成)

```ruby
# frozen_string_literal: true

# 認証関連の設定モジュール
#
# ログイン制限機能を制御するためのフィーチャーフラグを提供します。
# このモジュールは将来的に削除予定です（ベータ版終了後、全員ログインOKになる予定）。
module Authentication
  # ログイン制限を有効にするかどうか
  #
  # @return [Boolean] ログイン制限が有効な場合true
  #
  # @example ベータ版期間中（デフォルト）
  #   Authentication.restrict_login? #=> true
  #
  # @example 全員ログインOKの場合（.kamal/secretsで RESTRICT_LOGIN=false に設定）
  #   Authentication.restrict_login? #=> false
  #
  # NOTE: ベータ版終了後に RESTRICT_LOGIN=false に切り替える予定
  def self.restrict_login?
    ENV.fetch("RESTRICT_LOGIN", "true") == "true"
  end
end
```

**約20行のコード**

### 2. `app/models/allowed_email.rb` (新規作成)

```ruby
# frozen_string_literal: true

# 許可メールアドレス管理モデル
#
# ベータ版期間中、ログインを許可するメールアドレスを管理します。
# このモデルは将来的に削除予定です（全員ログインOKになる予定）。
class AllowedEmail < ApplicationRecord
  # バリデーション
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  # スコープ
  scope :active, -> { where(active: true) }

  # メールアドレスの正規化（保存前に小文字化）
  before_validation :normalize_email

  # ログイン許可チェック
  #
  # @param email [String] チェック対象のメールアドレス
  # @return [Boolean] ログインが許可されている場合true
  #
  # NOTE: このメソッドは将来的に削除予定（全員ログインOKになる予定）
  def self.allowed?(email)
    # ログイン制限が無効なら常にtrue
    return true unless Authentication.restrict_login?

    # メールアドレスを小文字化して検索
    active.exists?([ "LOWER(email) = ?", email.to_s.downcase ])
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.strip if email.present?
  end
end
```

**約40行のコード**

### 3. `app/controllers/application_controller.rb` (既存ファイルを変更)

```ruby
class ApplicationController < ActionController::Base
  # (省略)

  def logged_in?
    return false unless current_user.present?

    # 🔑 ログイン制限チェック（将来的に削除予定）
    # RESTRICT_LOGIN=falseの場合、この制限はスキップされる
    if Authentication.restrict_login?
      unless AllowedEmail.allowed?(current_user.email)
        Rails.logger.info "Login restricted: #{current_user.email} is not in allowed list"
        return false
      end
    end

    true
  end
end
```

**約15行のコード（変更部分のみ）**

### 4. `app/controllers/admin/allowed_emails_controller.rb` (新規作成)

```ruby
module Admin
  # 許可メールアドレス管理コントローラー
  #
  # 管理者が許可メールアドレスの追加・削除を行うためのCRUDインターフェース。
  # このコントローラーは将来的に削除予定（全員ログインOKになる予定）。
  class AllowedEmailsController < Admin::ApplicationController
    before_action :set_allowed_email, only: [ :destroy, :toggle_notified ]

    def index
      @allowed_emails = AllowedEmail.order(created_at: :desc).page(params[:page]).per(20)
    end

    def new
      @allowed_email = AllowedEmail.new
    end

    def create
      @allowed_email = AllowedEmail.new(allowed_email_params)

      if @allowed_email.save
        redirect_to admin_allowed_emails_path, notice: "#{@allowed_email.email} を許可リストに追加しました"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      email = @allowed_email.email
      @allowed_email.destroy!
      redirect_to admin_allowed_emails_path, notice: "#{email} を許可リストから削除しました"
    end

    def toggle_notified
      if @allowed_email.notified_at.present?
        @allowed_email.update!(notified_at: nil)
      else
        @allowed_email.update!(notified_at: Time.current)
      end

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_allowed_emails_path }
      end
    end

    private

    def set_allowed_email
      @allowed_email = AllowedEmail.find(params[:id])
    end

    def allowed_email_params
      params.require(:allowed_email).permit(:email, :note)
    end
  end
end
```

**約60行のコード**

### 5. `spec/models/allowed_email_spec.rb` (新規作成)

```ruby
require 'rails_helper'

RSpec.describe AllowedEmail, type: :model do
  describe ".allowed?" do
    before do
      # フィーチャーフラグをデフォルト（有効）に設定
      allow(Authentication).to receive(:restrict_login?).and_return(true)
    end

    context "ログイン制限が有効な場合" do
      it "許可リストに含まれるメールアドレスはtrueを返す" do
        AllowedEmail.create!(email: "allowed@example.com", active: true)
        expect(AllowedEmail.allowed?("allowed@example.com")).to be true
      end

      it "許可リストに含まれないメールアドレスはfalseを返す" do
        expect(AllowedEmail.allowed?("not-allowed@example.com")).to be false
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

      it "許可リストに含まれなくてもtrueを返す" do
        expect(AllowedEmail.allowed?("not-in-list@example.com")).to be true
      end
    end
  end
end
```

**約40行のコード（抜粋）**

---

## レビュー課題

### Q1. フィーチャーフラグの基本理解（初級）🟢

以下の質問に答えてください。

1. フィーチャーフラグとは何ですか？この設計パターンの主な目的を1-2文で説明してください。
2. `Authentication.restrict_login?` メソッドのデフォルト値が `"true"` である理由は何ですか？
3. 「削除容易性」とは何ですか？なぜフィーチャーフラグパターンで重要なのですか？

**回答時間の目安**: 5分

<details>
<summary>解答を表示</summary>

### A1. フィーチャーフラグの基本理解

**1. フィーチャーフラグとは何ですか？**

フィーチャーフラグ（Feature Flag）とは、コードを変更せずに機能のON/OFFを切り替える設計パターンです。主な目的は、デプロイ不要で機能を制御し、段階的リリースや即座のロールバックを実現することです。

**2. デフォルト値が `"true"` である理由:**

デフォルト値を `"true"` にすることで、環境変数が未設定の場合に**安全な方向**（ログイン制限ON）にフォールバックします。これは**セキュリティ優先**の設計思想です。

```ruby
ENV.fetch("RESTRICT_LOGIN", "true") == "true"
#                           ^^^^^^
#                           デフォルト値: ログイン制限ON（安全な方向）
```

もしデフォルト値が `"false"` だった場合、環境変数の設定ミスで全員がログインできてしまう危険性があります。

**3. 削除容易性とは？**

削除容易性とは、将来的に機能を削除する際に、**少ない変更で確実に削除できる**ことを指します。

フィーチャーフラグパターンで重要な理由：
- ベータ版限定機能など、**将来的に削除予定**の機能を実装する場合、削除が困難な設計だと技術的負債になる
- フィーチャーフラグパターンでは、以下の工夫で削除容易性を確保：
  - 絵文字（🔑）でマーキング
  - コメントで削除予定を明記
  - ファイル単位で削除可能な構造（モジュール、モデル、コントローラーを分離）
  - 環境変数でOFFにすれば、コード削除前に動作確認可能

</details>

---

### Q2. 実装の妥当性判断（中級）🟡

以下の実装の妥当性を判断してください。

1. `AllowedEmail.allowed?` メソッドで、なぜ早期リターン（`return true unless Authentication.restrict_login?`）を使っているのですか？この設計のメリットを2つ挙げてください。
2. 環境変数のデフォルト値を `"true"` にしたのは正しい判断ですか？もしデフォルト値を `"false"` にしたらどんな問題が起きる可能性がありますか？
3. `AllowedEmail.allowed?` で `LOWER(email)` を使っている理由は何ですか？単純に `active.where(email: email.to_s.downcase).exists?` ではダメなのですか？

**回答時間の目安**: 10分

<details>
<summary>解答を表示</summary>

### A2. 実装の妥当性判断

**1. 早期リターンのメリット:**

```ruby
def self.allowed?(email)
  # ログイン制限が無効なら常にtrue
  return true unless Authentication.restrict_login?
  #        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  #        フィーチャーフラグがOFFならここで終了

  # 以下のコードは RESTRICT_LOGIN=true の場合のみ実行される
  active.exists?([ "LOWER(email) = ?", email.to_s.downcase ])
end
```

**メリット1: 可読性の向上**
- ネストの深さを減らす（if文の中にif文を書かない）
- コードの意図が明確（「制限なしなら即座にtrue」が最初に分かる）

**メリット2: パフォーマンス向上**
- フィーチャーフラグがOFFの場合、DB検索をスキップ
- 本番環境で全員ログインOKになったら、毎回のログインチェックで不要なDB検索が行われない

**メリット3: 削除容易性**
- フィーチャーフラグをOFFにすれば、以降のコードは実行されない
- コード削除前に、フィーチャーフラグOFFで動作確認できる

**2. デフォルト値を `"false"` にした場合の問題:**

```ruby
# ❌ アンチパターン
ENV.fetch("RESTRICT_LOGIN", "false") == "true"
#                           ^^^^^^^
#                           デフォルト値: ログイン制限OFF（危険！）
```

**問題点:**
- 環境変数の設定ミス（`RESTRICT_LOGIN`を設定し忘れた場合）、**全員がログインできてしまう**
- ベータ版期間中に全員ログインOKになってしまい、意図しないユーザーが流入
- セキュリティ上のリスク（不正アクセス、スパム）

**セキュリティ優先の原則:**
- デフォルト値は常に**安全な方向**（制限あり、権限なし、機能OFF）に設定
- 明示的に環境変数を設定した場合のみ、制限を緩和する

**3. `LOWER(email)` を使う理由:**

**問題のあるコード:**

```ruby
# ❌ 問題あり
active.where(email: email.to_s.downcase).exists?
```

**問題点:**
- DBに保存されているメールアドレスが大文字の場合、マッチしない
- 例: DB に `Test@Example.com` が保存されている場合
  - Ruby側で `downcase` → `test@example.com`
  - DBには `Test@Example.com` が保存
  - マッチしない ❌

**正しいコード:**

```ruby
# ✅ 正しい
active.exists?([ "LOWER(email) = ?", email.to_s.downcase ])
```

**理由:**
- DB側とRuby側の**両方で小文字化**してから比較
- 例: DB に `Test@Example.com` が保存されている場合
  - DB側: `LOWER(email)` → `test@example.com`
  - Ruby側: `email.to_s.downcase` → `test@example.com`
  - マッチする ✅

**補足: `normalize_email` コールバック**

```ruby
before_validation :normalize_email

private

def normalize_email
  self.email = email.to_s.downcase.strip if email.present?
end
```

- 保存前にメールアドレスを小文字化
- DBには常に小文字で保存される
- しかし、既存データに大文字が含まれている可能性があるため、検索時も `LOWER()` を使う

**ベストプラクティス:**
- 保存時: `before_validation :normalize_email` で小文字化
- 検索時: `LOWER(email)` で小文字化（念のため）
- 両方実装することで、データの一貫性を確保

</details>

---

### Q3. 削除容易性の確保（中級〜上級）🟡🔴

以下の質問に答えてください。

1. このPRの設計で、`RESTRICT_LOGIN=false` に設定するだけで機能を削除できる設計になっていますか？その理由を説明してください。
2. ベータ版終了後、ログイン制限機能を完全に削除する場合、どのファイルを削除すればよいですか？最低5つ挙げてください。
3. フィーチャーフラグを削除するタイミングはいつが適切ですか？削除の判断基準を3つ挙げてください。

**回答時間の目安**: 15分

<details>
<summary>解答を表示</summary>

### A3. 削除容易性の確保

**1. `RESTRICT_LOGIN=false` で機能を削除できる設計か？**

**結論: Yes、削除できる設計になっています。**

**理由:**

**Phase 1: フィーチャーフラグをOFF（環境変数変更のみ）**

```bash
# .kamal/secrets
RESTRICT_LOGIN=false
```

この時点で、以下のコードが**実行されなくなる**：

```ruby
# app/models/allowed_email.rb
def self.allowed?(email)
  return true unless Authentication.restrict_login?
  #        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  #        ここで即座にtrueを返すため、以下のコードは実行されない

  # 以下は実行されない ✅
  active.exists?([ "LOWER(email) = ?", email.to_s.downcase ])
end
```

```ruby
# app/controllers/application_controller.rb
def logged_in?
  return false unless current_user.present?

  if Authentication.restrict_login?
    # ここは実行されない ✅
    unless AllowedEmail.allowed?(current_user.email)
      Rails.logger.info "Login restricted: #{current_user.email} is not in allowed list"
      return false
    end
  end

  true
end
```

**結果:**
- `AllowedEmail` モデルは参照されない
- `allowed_emails` テーブルは参照されない
- 全員がログイン可能になる
- **コード削除前に、本番環境で動作確認できる** 🎉

**Phase 2: 様子見期間（1-2週間）**

- 問題がないか監視
- スパムや不正アクセスの有無をチェック
- 問題があれば `RESTRICT_LOGIN=true` に戻すだけで復旧可能

**Phase 3: コード削除（安定稼働確認後）**

問題なければ、コードを削除（次の質問で詳細）

**2. 削除すべきファイル（最低5つ）:**

**必須削除ファイル:**

1. **`config/initializers/authentication.rb`** - フィーチャーフラグの定義
2. **`app/models/allowed_email.rb`** - AllowedEmailモデル
3. **`app/controllers/admin/allowed_emails_controller.rb`** - 管理者画面コントローラー
4. **`app/views/admin/allowed_emails/`** - 管理者画面ビュー（ディレクトリごと）
5. **`spec/models/allowed_email_spec.rb`** - AllowedEmailモデルのテスト

**追加で変更が必要なファイル:**

6. **`app/controllers/application_controller.rb`** - 認証チェック部分（🔑マーク）を削除

   ```ruby
   # Before
   def logged_in?
     return false unless current_user.present?

     # 🔑 ログイン制限チェック（将来的に削除予定）
     if Authentication.restrict_login?
       unless AllowedEmail.allowed?(current_user.email)
         Rails.logger.info "Login restricted: #{current_user.email} is not in allowed list"
         return false
       end
     end

     true
   end

   # After
   def logged_in?
     current_user.present?
   end
   ```

7. **`config/routes.rb`** - `Admin::AllowedEmailsController` のルート削除

   ```ruby
   # Before
   namespace :admin do
     resources :allowed_emails, only: [ :index, :new, :create, :destroy ] do
       member do
         patch :toggle_notified
       end
     end
   end

   # After
   namespace :admin do
     # (削除)
   end
   ```

8. **`app/views/admin/dashboard/index.html.slim`** - 管理者ダッシュボードのリンク削除

   ```slim
   / Before
   - if Authentication.restrict_login?
     .bg-white.p-6.rounded-lg.shadow
       h2.text-xl.font-bold.mb-4 ✉️ 許可メールアドレス管理
       p.text-gray-600.mb-4 ベータ版期間中のログイン制限を管理
       = link_to "管理画面へ", admin_allowed_emails_path, class: "btn btn-primary"

   / After
   / (削除)
   ```

9. **マイグレーション作成** - `allowed_emails` テーブル削除

   ```bash
   rails g migration DropAllowedEmails
   ```

   ```ruby
   class DropAllowedEmails < ActiveRecord::Migration[8.1]
     def up
       drop_table :allowed_emails
     end

     def down
       # 復旧用（念のため）
       create_table :allowed_emails do |t|
         t.string :email, null: false, index: { unique: true }
         t.boolean :active, default: true, null: false
         t.text :note
         t.datetime :notified_at
         t.timestamps
       end
     end
   end
   ```

10. **`.kamal/secrets`** - `RESTRICT_LOGIN` 環境変数削除

**削除のチェックリスト:**

- [ ] `config/initializers/authentication.rb` 削除
- [ ] `app/models/allowed_email.rb` 削除
- [ ] `app/controllers/admin/allowed_emails_controller.rb` 削除
- [ ] `app/views/admin/allowed_emails/` ディレクトリ削除
- [ ] `spec/models/allowed_email_spec.rb` 削除
- [ ] `app/controllers/application_controller.rb` の🔑マーク部分削除
- [ ] `config/routes.rb` の `Admin::AllowedEmailsController` ルート削除
- [ ] `app/views/admin/dashboard/index.html.slim` のリンク削除
- [ ] `db/migrate/YYYYMMDDHHMMSS_drop_allowed_emails.rb` 作成
- [ ] `.kamal/secrets` の `RESTRICT_LOGIN` 削除
- [ ] RuboCop、Brakeman 実行
- [ ] テスト実行
- [ ] デプロイ

**削除の容易性:**
- 削除ファイル: 5ファイル
- 変更ファイル: 3ファイル
- マイグレーション: 1ファイル
- **合計: 10箇所の変更で完全削除** ✅

🔑 絵文字でマーキングしておくことで、削除対象を簡単に見つけられます。

```bash
# 削除対象をgrepで検索
grep -r "🔑" app/
```

**3. フィーチャーフラグを削除するタイミング:**

**削除の判断基準（3つ）:**

**基準1: 安定稼働期間の確保**
- フィーチャーフラグをOFFにしてから**最低1-2週間**の安定稼働を確認
- この期間に以下を監視：
  - エラーログ（Sentry等）
  - ユーザーからの問い合わせ
  - パフォーマンスメトリクス
- 問題が発生した場合、即座にフィーチャーフラグをONに戻せる（安全弁）

**基準2: ビジネス要件の確定**
- 「ベータ版終了」の判断が確定している
- 今後、再度ログイン制限を有効にする可能性がない
- 課金機能など、代替の制限機能が実装済み

**基準3: コードの明確な分離**
- 削除対象のコードが明確にマーキングされている（🔑絵文字、コメント）
- 削除時の影響範囲が明確（どのファイルを削除すればよいか一目瞭然）
- テストが充実している（削除後のリグレッションを防ぐ）

**削除を急いではいけない理由:**
- フィーチャーフラグは「保険」の役割
- 削除してしまうと、問題発生時にロールバックできない
- コード量は多くない（約150行）ため、技術的負債としての影響は小さい

**削除を遅らせてはいけない理由:**
- 削除予定のコードを放置すると、技術的負債が蓄積
- 新しいメンバーが「このコードは何？」と混乱する
- メンテナンスコストが増加（テスト、ドキュメント、コードレビュー）

**理想的なタイミング:**
- フィーチャーフラグOFFで1-2週間の安定稼働を確認
- ビジネス要件が確定（ベータ版終了の判断）
- テストが充実している
- ドキュメントが整備されている（削除手順が明確）

</details>

---

### Q4. 環境変数 vs DB管理の判断（上級）🔴

以下の質問に答えてください。

1. Day 28以前は、`ALLOWED_EMAILS` を環境変数（カンマ区切りの文字列）で管理していました。Day 28では、`RESTRICT_LOGIN`（環境変数）と`allowed_emails`（DB）の2段階アプローチに変更しました。なぜこの設計が優れているのですか？
2. `RESTRICT_LOGIN` を環境変数で管理し、`allowed_emails` をDBで管理した理由は何ですか？それぞれのメリット・デメリットを表形式で比較してください。
3. どのような場合に環境変数で管理し、どのような場合にDB管理を選ぶべきですか？判断基準を3つ以上挙げてください。

**回答時間の目安**: 10分

<details>
<summary>解答を表示</summary>

### A4. 環境変数 vs DB管理の判断

**1. 2段階アプローチが優れている理由:**

**Day 28以前（アンチパターン）:**

```bash
# .kamal/secrets
ALLOWED_EMAILS="user1@example.com,user2@example.com,user3@example.com"
```

**問題点:**
- ユーザー追加のたびに環境変数を編集 → デプロイが必要
- デプロイのたびにダウンタイムリスク
- メールアドレスがカンマ区切りの文字列（データ構造として不適切）
- 履歴管理ができない（誰がいつ追加したか不明）
- 管理者メモを追加できない

**Day 28の設計（ベストプラクティス）:**

```bash
# .kamal/secrets
RESTRICT_LOGIN=true  # 機能のON/OFF（環境変数）
```

```sql
-- allowed_emails テーブル（DB）
CREATE TABLE allowed_emails (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR NOT NULL UNIQUE,
  active BOOLEAN DEFAULT TRUE,
  note TEXT,
  notified_at TIMESTAMP,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

**メリット:**
- **機能のON/OFF**: 環境変数で制御（デプロイ不要）
- **データリスト**: DBで管理（リアルタイム追加、履歴管理、管理者メモ）
- **ゼロダウンタイム**: ユーザー追加時にデプロイ不要
- **段階的移行**: `RESTRICT_LOGIN=false` で即座に全員ログインOKに切り替え可能
- **削除容易性**: 環境変数を削除するだけで機能OFF、コード削除も容易

**設計の優位性:**
- **関心の分離**: 機能のON/OFF（環境変数）とデータ管理（DB）を分離
- **柔軟性**: 機能のON/OFFとデータ追加を独立して制御
- **スケーラビリティ**: メールアドレスが数百件に増えても問題なし

**2. 環境変数 vs DB管理の比較表:**

| 項目 | 環境変数 | データベース |
|------|----------|--------------|
| **変更頻度** | 低（機能のON/OFFのみ） | 高（ユーザー追加のたび） |
| **デプロイ** | 不要（`kamal env push`のみ） | 不要（管理画面から追加） |
| **データ量** | 少（boolean値、短い文字列） | 多（数十〜数百件） |
| **データ構造** | シンプル（文字列、数値） | 複雑（複数カラム、リレーション） |
| **履歴管理** | 不要（ON/OFFの履歴は不要） | 必要（`created_at`, `note`カラム） |
| **検索機能** | 不要 | 必要（ページネーション、ソート、フィルター） |
| **削除容易性** | 高（環境変数を削除するだけ） | 中（テーブル削除が必要） |
| **バージョン管理** | 可能（`.kamal/secrets`をGitで管理） | 不可（DBの内容はGit管理外） |
| **セキュリティ** | 高（コードから分離） | 中（DBアクセス権限が必要） |
| **テスト** | モックが必要 | 通常のRSpecテストでOK |
| **本番環境の変更** | 慎重に（間違えると全体に影響） | 容易（1件ずつ追加・削除） |
| **ロールバック** | 困難（環境変数を元に戻す） | 容易（レコードを削除） |

**3. 判断基準:**

**環境変数で管理すべき場合:**

**基準1: 機能のON/OFF（フィーチャーフラグ）**
- 機能全体を有効/無効にする（boolean値）
- 例: `RESTRICT_LOGIN`, `PREMIUM_FEATURE`, `NEW_UI`

**基準2: アプリケーション全体に影響する設定**
- すべてのインスタンスで同じ値を使う
- 例: `RAILS_ENV`, `SECRET_KEY_BASE`, `DATABASE_URL`

**基準3: 秘密情報（シークレット）**
- パスワード、APIキー、トークン
- 例: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `SENTRY_DSN`

**基準4: インフラ設定**
- ホスト名、ポート番号、タイムアウト値
- 例: `REDIS_URL`, `MEMCACHED_SERVERS`, `SMTP_HOST`

**基準5: 変更頻度が低い**
- 月1回以下の変更頻度
- 変更時にデプロイしても問題ない

**データベースで管理すべき場合:**

**基準1: データリスト（複数レコード）**
- メールアドレスリスト、許可IPリスト、ブロックリスト
- 例: `allowed_emails`, `blocked_ips`, `feature_flags`（レコード単位で管理）

**基準2: 変更頻度が高い**
- 日1回以上の変更頻度
- リアルタイム追加が必要
- 例: ユーザー追加、コンテンツ追加、設定変更

**基準3: 履歴管理が必要**
- 誰がいつ追加したか記録したい
- `created_at`, `updated_at`, `note`カラムが必要
- 例: ユーザー管理、監査ログ、変更履歴

**基準4: 複雑なデータ構造**
- 複数カラム（email, note, active, notified_at など）
- リレーション（外部キー制約）
- 例: ユーザー、レッスン、カテゴリー

**基準5: 検索・ページネーション・ソートが必要**
- 管理画面で一覧表示したい
- 検索機能が必要
- 例: 管理者画面の一覧ページ

**基準6: 削除が容易**
- レコード単位で削除できる
- 削除してもアプリ全体に影響しない
- 例: ユーザー削除、メールアドレス削除

**判断基準の例:**

| データ | 判断 | 理由 |
|--------|------|------|
| `RESTRICT_LOGIN` | 環境変数 | 機能のON/OFF、boolean値、全体に影響 |
| `allowed_emails` | DB | データリスト、変更頻度高、履歴管理が必要 |
| `GOOGLE_CLIENT_ID` | 環境変数 | 秘密情報、全体で1つ、変更頻度低 |
| `users` | DB | データリスト、複雑な構造、検索が必要 |
| `ADMIN_EMAILS` | 環境変数 or DB | 変更頻度による（低いなら環境変数、高いならDB） |
| `SENTRY_DSN` | 環境変数 | 秘密情報、全体で1つ |
| `feature_flags`（テーブル） | DB | 複数のフィーチャーフラグを管理、UI上でON/OFF切り替え |

**Day 28の判断:**
- `RESTRICT_LOGIN`: 環境変数（機能のON/OFF、boolean値、全体に影響）
- `allowed_emails`: DB（データリスト、変更頻度高、履歴管理が必要）

この判断により、**ゼロダウンタイムでのユーザー追加**と**段階的な機能削除**が実現できました。

</details>

---

## 総合評価

### 基準

- **Q1を正解**: フィーチャーフラグの基本概念を理解している
- **Q2を正解**: フィーチャーフラグの実装パターンを理解している
- **Q3を正解**: 削除容易性を確保した設計ができる
- **Q4を正解**: 環境変数とDB管理の使い分けができる

### 次のステップ

- **Q1のみ正解**: フィーチャーフラグの基本は理解できています。実装パターン（早期リターン、デフォルト値の設定）を復習しましょう。
- **Q1-Q2正解**: 実装パターンは理解できています。削除容易性の確保（マーキング、コメント、ファイル分離）を学びましょう。
- **Q1-Q3正解**: 削除容易性まで理解できています。環境変数とDB管理の使い分けを学び、実践的な判断力を身につけましょう。
- **全問正解**: 🎉 フィーチャーフラグパターンを完全に理解しています！次は、実際のプロジェクトでフィーチャーフラグを導入してみましょう。

## 参考資料

- [フィーチャーフラグパターン](../topics/03_advanced/09_feature_flag_pattern.md)
- [Day 28の日報](../../daily_reports/2025-12-28.md)
- [CLAUDE_STABILITY_AND_OPERATIONS.md](../../../CLAUDE_STABILITY_AND_OPERATIONS.md)
- 実際のPR: #96

---

**作成日**: 2026-01-03
**難易度**: 🟡 中級
**推定時間**: 30分〜1時間
