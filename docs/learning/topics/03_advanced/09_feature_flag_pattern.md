# フィーチャーフラグパターン

**難易度**: 🟡 中級
**推定学習時間**: 1〜2時間
**対応する日報**: Day 28
**関連PR**: #96

---

## 🎯 学習目標

この教材を学ぶことで、以下ができるようになります：

- フィーチャーフラグパターンの基本を理解する
- 環境変数による機能ON/OFFの実装ができる
- 削除容易性を確保した設計ができる
- 本番環境の安定性と開発の柔軟性のバランスを取れる

---

## 📚 前提知識

この教材を理解するには、以下の知識が必要です：

- Railsの環境変数管理（ENV、credentials）
- 基本的な条件分岐
- データベース設計の基礎
- モデル・コントローラー・ビューの基本構造

---

## 📖 本編

### 概要

**フィーチャーフラグ（Feature Flag）**とは、コードを変更せずに機能のON/OFFを切り替える設計パターンです。別名「フィーチャートグル（Feature Toggle）」とも呼ばれます。

Day 28のTypnixプロジェクトでは、ベータ版期間中の**ログイン制限機能**にフィーチャーフラグパターンを導入しました。この機能は将来的に削除予定であるため、以下の要件を満たす必要がありました：

**要件:**
1. ベータ版期間中：許可メールアドレスのみログインOK
2. ベータ版終了後：全員ログインOK
3. 切り替えは**デプロイ不要**で実現
4. 問題発生時は**即座にロールバック**可能
5. 最終的には**簡単に削除**できる設計

フィーチャーフラグパターンを使うことで、これらの要件をすべて満たすことができました。

---

### 実装前（アンチパターン / 課題）

フィーチャーフラグを導入する前の状況を確認しましょう。

#### アンチパターン1: 直接本番環境で新機能を公開

```ruby
# app/controllers/application_controller.rb
def logged_in?
  return false unless current_user.present?

  # 全員ログインOK（ベータ版では問題）
  true
end
```

**問題点:**
- ベータ版期間中、誰でもログインできてしまう
- 段階的リリースができない
- 問題発生時の切り戻しが困難（コード変更＋デプロイが必要）

#### アンチパターン2: 環境変数の直接参照が散在

```ruby
# app/controllers/application_controller.rb
def logged_in?
  return false unless current_user.present?

  # 環境変数を直接参照（DRY原則違反）
  if ENV["ALLOWED_EMAILS"].split(",").include?(current_user.email)
    true
  else
    false
  end
end

# app/controllers/sessions_controller.rb
def create
  # 同じチェックを重複実装
  if ENV["ALLOWED_EMAILS"].split(",").include?(user.email)
    # ログイン処理
  else
    # エラー
  end
end
```

**問題点:**
- 環境変数の直接参照が複数箇所に散在
- 同じロジックの重複（DRY原則違反）
- 将来的な削除が困難（どこに環境変数参照があるか追跡が必要）
- テストが書きにくい（環境変数のモックが必要）

#### アンチパターン3: 削除が困難なコード

```ruby
# app/models/user.rb
class User < ApplicationRecord
  # ベータ版終了後に削除したいが、どこで使われているか不明
  def allowed?
    ENV["ALLOWED_EMAILS"].split(",").include?(email)
  end
end

# app/controllers/application_controller.rb
def logged_in?
  current_user&.allowed?
end

# app/controllers/sessions_controller.rb
def create
  if user.allowed?
    # ...
  end
end

# app/views/admin/users/index.html.slim
- if user.allowed?
  span.badge ログイン許可
```

**問題点:**
- 機能が複数のレイヤー（モデル、コントローラー、ビュー）に散在
- 削除時にどのファイルを変更すればよいか不明
- 削除漏れのリスク
- 技術的負債の蓄積

---

### 実装後（ベストプラクティス）

フィーチャーフラグパターンを導入後のコードを見てみましょう。

#### ステップ1: フィーチャーフラグ初期化ファイル

```ruby
# config/initializers/authentication.rb
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

**改善点:**
- 環境変数の参照を1箇所に集約
- デフォルト値を明示（`"true"`）
- コメントで削除予定を明記
- YARDoc形式のドキュメント

#### ステップ2: AllowedEmailモデル

```ruby
# app/models/allowed_email.rb
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

**改善点:**
- フィーチャーフラグによる早期リターン（`return true unless Authentication.restrict_login?`）
- 削除予定を明記
- バリデーションとスコープの適切な実装
- 大文字小文字を区別しない検索（PostgreSQLの`LOWER()`関数）

#### ステップ3: ApplicationControllerの認証チェック

```ruby
# app/controllers/application_controller.rb
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

**改善点:**
- 絵文字（🔑）でマーキング（削除対象を明確化）
- コメントで削除予定を明記
- ログ出力（運用時のデバッグに役立つ）
- 一箇所にロジックを集約（DRY原則）

#### ステップ4: 管理者画面CRUD

```ruby
# app/controllers/admin/allowed_emails_controller.rb
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

**改善点:**
- クラスコメントで削除予定を明記
- 適切な継承構造（`Admin::ApplicationController`を継承）
- ページネーション対応（20件/ページ）
- Turbo対応（非同期削除）

---

### 解説

#### なぜこの設計が優れているのか

**1. 段階的リリース（Gradual Rollout）**

フィーチャーフラグを使うことで、新機能を段階的にリリースできます。

```ruby
# Phase 1: ベータ版（一部ユーザーのみ）
RESTRICT_LOGIN=true  # 許可メールアドレスのみログインOK

# Phase 2: 全員に公開（デプロイ不要）
RESTRICT_LOGIN=false  # 全員ログインOK

# Phase 3: 様子見期間（1-2週間）
# 問題があれば RESTRICT_LOGIN=true に戻すだけで復旧可能

# Phase 4: コード削除（安定稼働確認後）
# Authentication モジュール、AllowedEmail モデル、管理者画面を削除
```

**2. 即座のロールバック（Instant Rollback）**

本番環境で問題が発生した場合、環境変数を変更するだけで即座にロールバックできます。

```bash
# 問題発生時（ログイン制限を再度有効化）
# .kamal/secrets を編集
RESTRICT_LOGIN=true

# VPSで環境変数を再読み込み（Kamalの場合、envコマンドで即座に反映）
kamal env push
```

**デプロイ不要**のため、ダウンタイムなしで切り戻しが可能です。

**3. A/Bテスト・カナリアリリース**

Typnixプロジェクトでは使用していませんが、フィーチャーフラグは以下のような高度な用途にも使えます：

```ruby
# A/Bテスト例
module Features
  def self.new_ui_enabled?(user)
    # ユーザーIDの偶奇で新UI・旧UIを切り替え
    return ENV["NEW_UI"] == "all" if ENV["NEW_UI"] == "all"
    user.id.even?
  end
end

# カナリアリリース例
module Features
  def self.experimental_feature?(user)
    # 管理者と一部のベータテスターのみ有効
    user.admin? || BETA_TESTER_IDS.include?(user.id)
  end
end
```

**4. 削除容易性の確保**

フィーチャーフラグパターンの最大の利点は、**削除容易性**です。

**削除対象のマーキング:**
- 🔑 絵文字でマーキング
- クラス・メソッドコメントに「削除予定」を明記
- ファイル単位で削除可能な構造

**削除時のチェックリスト:**
1. `config/initializers/authentication.rb` - ファイル削除
2. `app/models/allowed_email.rb` - ファイル削除
3. `app/controllers/admin/allowed_emails_controller.rb` - ファイル削除
4. `app/views/admin/allowed_emails/` - ディレクトリ削除
5. `app/controllers/application_controller.rb` - 認証チェック部分（🔑マーク）を削除
6. `config/routes.rb` - `Admin::AllowedEmailsController`のルート削除
7. マイグレーション作成（`drop_table :allowed_emails`）

**5. 環境変数 vs データベース管理の使い分け**

Typnixプロジェクトでは、以下の2段階アプローチを採用しました：

**環境変数で管理するもの:**
- `RESTRICT_LOGIN` - 機能のON/OFF（フィーチャーフラグ）

**データベースで管理するもの:**
- `allowed_emails` テーブル - 許可メールアドレスのリスト

**理由:**

| 項目 | 環境変数 | データベース |
|------|----------|--------------|
| **変更頻度** | 低（機能のON/OFFのみ） | 高（ユーザー追加のたび） |
| **デプロイ** | 不要（`kamal env push`のみ） | 不要（管理画面から追加） |
| **データ量** | 少（boolean値のみ） | 多（数十〜数百件） |
| **履歴管理** | 不要 | 必要（`created_at`, `note`カラム） |
| **削除容易性** | 高（環境変数を削除するだけ） | 中（テーブル削除が必要） |

**Day 28以前の問題点:**
- `ALLOWED_EMAILS` を環境変数で管理（カンマ区切りの文字列）
- ユーザー追加のたびにデプロイが必要
- デプロイのたびにダウンタイムリスク

**Day 28の改善:**
- `RESTRICT_LOGIN` を環境変数で管理（機能のON/OFF）
- `allowed_emails` をデータベースで管理（メールアドレスリスト）
- ユーザー追加はリアルタイム（デプロイ不要）

---

#### 実装のポイント

**1. デフォルト値の設定**

```ruby
ENV.fetch("RESTRICT_LOGIN", "true") == "true"
#                           ^^^^^^
#                           デフォルト値は "true"（ログイン制限ON）
```

**理由:**
- 環境変数が未設定の場合、**安全な方向**（ログイン制限ON）にフォールバック
- セキュリティ優先の設計

**2. 早期リターン（Early Return）パターン**

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

**利点:**
- 可読性の向上（ネストの深さを減らす）
- パフォーマンス向上（不要なDB検索をスキップ）
- 削除容易性（フィーチャーフラグをOFFにすれば、以降のコードは実行されない）

**3. コメントとマーキング**

```ruby
# 🔑 ログイン制限チェック（将来的に削除予定）
# RESTRICT_LOGIN=falseの場合、この制限はスキップされる
if Authentication.restrict_login?
  # ...
end
```

**利点:**
- 絵文字（🔑）で視覚的にマーキング
- 将来的な削除対象を明確化
- コードレビュー時に気づきやすい
- grepで検索可能（`grep -r "🔑" app/`）

**4. ログ出力**

```ruby
unless AllowedEmail.allowed?(current_user.email)
  Rails.logger.info "Login restricted: #{current_user.email} is not in allowed list"
  return false
end
```

**利点:**
- 本番環境でのデバッグが容易
- ユーザーからの問い合わせ時に原因特定が早い
- セキュリティ監査（誰がログインを試みたか）

**5. 大文字小文字を区別しない検索**

```ruby
active.exists?([ "LOWER(email) = ?", email.to_s.downcase ])
#               ^^^^^^^^^^^^^^^^^^
#               PostgreSQLの LOWER() 関数を使用
```

**理由:**
- メールアドレスは大文字小文字を区別しない（RFC 5321）
- `test@example.com` と `TEST@EXAMPLE.COM` は同一

**代替手段との比較:**

```ruby
# ❌ アンチパターン1: case_sensitiveオプション（ActiveRecordのバリデーション）
validates :email, uniqueness: { case_sensitive: false }
# ⇒ バリデーションでは使えるが、検索では使えない

# ❌ アンチパターン2: 小文字化してから比較
active.where(email: email.to_s.downcase).exists?
# ⇒ DB側で小文字化されていない場合、マッチしない

# ✅ ベストプラクティス: LOWER()関数
active.exists?([ "LOWER(email) = ?", email.to_s.downcase ])
# ⇒ DB側とRuby側の両方で小文字化
```

---

### Typnixプロジェクトでの実例

#### 使用箇所1: ApplicationController（認証チェック）

**ファイル**: `app/controllers/application_controller.rb`

```ruby
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
```

**呼び出し元:**
- すべてのコントローラー（`before_action :authenticate_user!`経由）
- ビューファイル（`if logged_in?`で分岐）

#### 使用箇所2: SessionsController（ログイン時のチェック）

**ファイル**: `app/controllers/sessions_controller.rb`

```ruby
def create
  # Google認証後の処理
  user = User.from_google_id_token(id_token)

  if user
    session[:user_id] = user.id

    # 🔑 ログイン制限チェック（将来的に削除予定）
    unless AllowedEmail.allowed?(user.email)
      session[:user_id] = nil
      flash[:alert] = "現在、ベータ版のためログインが制限されています"
      redirect_to root_path
      return
    end

    redirect_to root_path, notice: "ログインしました"
  else
    flash[:alert] = "ログインに失敗しました"
    redirect_to root_path
  end
end
```

**Day 28での修正内容:**
- 古い `User.email_allowed?` メソッドを削除
- `AllowedEmail.allowed?` に統一
- フラッシュメッセージ使用（JavaScriptのalert()を廃止）

#### 使用箇所3: 管理者ダッシュボード

**ファイル**: `app/views/admin/dashboard/index.html.slim`

```slim
.container.mx-auto.px-4.py-8
  h1.text-3xl.font-bold.mb-8 管理者ダッシュボード

  .grid.gap-6.mb-8
    / (省略)

    / 🔑 ベータ版期間中のみ表示（将来的に削除予定）
    - if Authentication.restrict_login?
      .bg-white.p-6.rounded-lg.shadow
        h2.text-xl.font-bold.mb-4 ✉️ 許可メールアドレス管理
        p.text-gray-600.mb-4 ベータ版期間中のログイン制限を管理
        = link_to "管理画面へ", admin_allowed_emails_path, class: "btn btn-primary"
```

**利点:**
- フィーチャーフラグがOFFになると、自動的にUIから消える
- コード削除時は、このif文ごと削除すればOK

---

### フィーチャーフラグの削除手順（将来）

ベータ版終了後、ログイン制限機能を削除する手順を示します。

#### Phase 1: ログイン制限を無効化（デプロイ不要）

```bash
# .kamal/secrets に追加（または変更）
RESTRICT_LOGIN=false
```

```bash
# VPSで環境変数を再読み込み
kamal env push
```

この時点で、`AllowedEmail` テーブルは参照されなくなり、全員がログイン可能になります。

**確認:**
```bash
# Railsコンソールで確認
$ kamal app exec -i 'bin/rails console'
> Authentication.restrict_login?
=> false

> AllowedEmail.allowed?("anyone@example.com")
=> true  # 誰でもログインOK
```

#### Phase 2: 様子見期間（1-2週間）

- ログイン制限なしで問題がないか確認
- スパムや不正アクセスの有無をチェック
- 問題があれば `RESTRICT_LOGIN=true` に戻すだけで復旧可能

#### Phase 3: コード削除（安定稼働確認後）

問題なければ、以下のコードを削除します。

**1. config/initializers/authentication.rb - ファイル削除**

```bash
git rm config/initializers/authentication.rb
```

**2. app/models/allowed_email.rb - ファイル削除**

```bash
git rm app/models/allowed_email.rb
```

**3. app/controllers/admin/allowed_emails_controller.rb - ファイル削除**

```bash
git rm app/controllers/admin/allowed_emails_controller.rb
```

**4. app/views/admin/allowed_emails/ - ディレクトリ削除**

```bash
git rm -r app/views/admin/allowed_emails
```

**5. app/controllers/application_controller.rb - 認証チェック部分を削除**

```ruby
# Before
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

# After
def logged_in?
  current_user.present?
end
```

**6. config/routes.rb - Admin::AllowedEmailsControllerのルート削除**

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

**7. db/migrate/YYYYMMDDHHMMSS_drop_allowed_emails.rb - テーブル削除マイグレーション**

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

```bash
rails db:migrate
```

**8. spec/models/allowed_email_spec.rb - テストファイル削除**

```bash
git rm spec/models/allowed_email_spec.rb
```

**9. .kamal/secrets - 環境変数削除**

```bash
# RESTRICT_LOGIN=false を削除
```

**10. コミット**

```bash
git add .
git commit -m "ログイン制限機能を削除（ベータ版終了）

- Authentication モジュール削除
- AllowedEmail モデル削除
- Admin::AllowedEmailsController 削除
- 管理者画面削除
- ApplicationController の認証チェック簡素化
- データベースから allowed_emails テーブル削除

RESTRICT_LOGIN 環境変数も不要になったため、.kamal/secrets から削除

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

**削除対象のファイル数:**
- 削除ファイル: 7ファイル
- 変更ファイル: 3ファイル
- **合計: 10箇所の変更で完全削除**

🔑 絵文字でマーキングしておくことで、削除対象を簡単に見つけられます。

---

### テスト実装

フィーチャーフラグのテストでは、**環境変数のモック**が重要です。

**ファイル**: `spec/models/allowed_email_spec.rb`

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

      it "無効化されたメールアドレスはfalseを返す" do
        AllowedEmail.create!(email: "inactive@example.com", active: false)
        expect(AllowedEmail.allowed?("inactive@example.com")).to be false
      end

      it "大文字小文字を区別せずにチェック" do
        AllowedEmail.create!(email: "test@example.com", active: true)
        expect(AllowedEmail.allowed?("TEST@EXAMPLE.COM")).to be true
      end
    end

    context "ログイン制限が無効な場合" do
      before do
        # フィーチャーフラグをOFF（無効）に設定
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

**テストのポイント:**

**1. モックの使用**

```ruby
allow(Authentication).to receive(:restrict_login?).and_return(true)
#                                                              ^^^^
#                                                              テスト用の戻り値を指定
```

**利点:**
- 環境変数を変更せずにテスト可能
- テストの独立性を確保（他のテストの影響を受けない）
- フィーチャーフラグON/OFFの両方をテスト

**2. context分け**

```ruby
context "ログイン制限が有効な場合" do
  # フィーチャーフラグONのテスト
end

context "ログイン制限が無効な場合" do
  # フィーチャーフラグOFFのテスト
end
```

**利点:**
- テストの可読性向上
- フィーチャーフラグの挙動を明確にテスト

**テスト実行結果:**

```bash
$ bundle exec rspec spec/models/allowed_email_spec.rb

AllowedEmail
  .allowed?
    ログイン制限が有効な場合
      許可リストに含まれるメールアドレスはtrueを返す
      許可リストに含まれないメールアドレスはfalseを返す
      無効化されたメールアドレスはfalseを返す
      大文字小文字を区別せずにチェック
    ログイン制限が無効な場合
      どんなメールアドレスでもtrueを返す
      許可リストに含まれなくてもtrueを返す

Finished in 0.12345 seconds (files took 1.23 seconds to load)
13 examples, 0 failures
```

---

## 💡 まとめ

### 重要ポイント

- ✅ **フィーチャーフラグパターン**は、機能のON/OFFをコード変更なしで切り替える設計パターン
- ✅ **3つのメリット**: 段階的リリース、即座のロールバック、A/Bテスト
- ✅ **削除容易性**を最優先に設計する（絵文字マーキング、コメント、ファイル単位の分離）
- ✅ **環境変数 vs DB管理**の使い分け: 機能ON/OFFは環境変数、データリストはDB
- ✅ **デフォルト値**は安全な方向に設定（セキュリティ優先）
- ✅ **早期リターン**パターンで可読性とパフォーマンスを向上
- ✅ **テスト**では環境変数のモックを使用（`allow().to receive().and_return()`）

### フィーチャーフラグの使いどころ

**使うべき場面:**
- 将来的に削除予定の機能（ベータ版限定機能など）
- 段階的にリリースしたい新機能
- A/Bテストを実施したい機能
- カナリアリリース（一部ユーザーのみに公開）

**使わない方がいい場面:**
- 恒久的な機能（削除予定がない）
- シンプルなON/OFFで管理できない複雑な制御
- パフォーマンスクリティカルな箇所（条件分岐のオーバーヘッド）

### 次のステップ

このトピックを理解したら、以下に進むことをお勧めします：

- [アーキテクチャ改善とリファクタリング](./07_architecture_improvements.md) - DRY原則、delegate パターン
- [セキュリティベストプラクティス](./08_security_best_practices.md) - 予約語システム、24時間制限
- [環境変数管理](../01_basics/03_environment_variables.md) - credentials、.kamal/secrets

---

## 🔗 関連教材

- [Review Test #09: フィーチャーフラグパターン](../../reviews/review_09_feature_flag_pattern.md)
- [Day 28の日報](../../../daily_reports/2025-12-28.md)
- [CLAUDE_STABILITY_AND_OPERATIONS.md](../../../../CLAUDE_STABILITY_AND_OPERATIONS.md)

---

## 📝 演習問題（オプション）

### 問題1: シンプルなフィーチャーフラグの実装

以下の要件を満たすフィーチャーフラグを実装してください。

**要件:**
- 「新しいUI」機能のフィーチャーフラグを作成
- 環境変数 `NEW_UI` で制御（デフォルト: `false`）
- `Features.new_ui_enabled?` メソッドで判定

<details>
<summary>解答例を表示</summary>

```ruby
# config/initializers/features.rb
module Features
  # 新しいUI機能を有効にするかどうか
  #
  # @return [Boolean] 新しいUIが有効な場合true
  #
  # NOTE: 安定稼働確認後に旧UIを削除し、このフラグも削除予定
  def self.new_ui_enabled?
    ENV.fetch("NEW_UI", "false") == "true"
  end
end
```

**使用例:**

```ruby
# app/controllers/application_controller.rb
def render_dashboard
  if Features.new_ui_enabled?
    render "dashboards/new_ui"
  else
    render "dashboards/old_ui"
  end
end
```

```slim
/ app/views/layouts/application.html.slim
- if Features.new_ui_enabled?
  = render "layouts/nav_new"
- else
  = render "layouts/nav_old"
```

**解説:**
- デフォルト値は `false`（新UIは安定していない可能性があるため、安全な方向）
- `Features` モジュールに集約（複数のフィーチャーフラグを管理しやすい）
- コメントで削除予定を明記

</details>

---

### 問題2: A/Bテスト用のフィーチャーフラグ

ユーザーIDの偶奇で新UI・旧UIを切り替えるフィーチャーフラグを実装してください。

**要件:**
- 環境変数 `NEW_UI` が `all` の場合、全員に新UIを表示
- 環境変数 `NEW_UI` が `test` の場合、偶数IDのユーザーのみ新UI
- 環境変数 `NEW_UI` が未設定の場合、全員旧UI

<details>
<summary>解答例を表示</summary>

```ruby
# config/initializers/features.rb
module Features
  # 新しいUI機能を有効にするかどうか（A/Bテスト対応）
  #
  # @param user [User] 対象ユーザー
  # @return [Boolean] 新しいUIが有効な場合true
  #
  # @example 全員に新UI
  #   ENV["NEW_UI"] = "all"
  #   Features.new_ui_enabled?(user) #=> true
  #
  # @example 偶数IDのユーザーのみ新UI（A/Bテスト）
  #   ENV["NEW_UI"] = "test"
  #   Features.new_ui_enabled?(user) #=> user.id.even?
  #
  # @example 全員旧UI（デフォルト）
  #   ENV["NEW_UI"] = nil
  #   Features.new_ui_enabled?(user) #=> false
  def self.new_ui_enabled?(user)
    case ENV["NEW_UI"]
    when "all"
      true
    when "test"
      user.id.even?
    else
      false
    end
  end
end
```

**使用例:**

```ruby
# app/controllers/application_controller.rb
def render_dashboard
  if Features.new_ui_enabled?(current_user)
    render "dashboards/new_ui"
  else
    render "dashboards/old_ui"
  end
end
```

**テスト:**

```ruby
# spec/lib/features_spec.rb
RSpec.describe Features do
  describe ".new_ui_enabled?" do
    let(:user_even) { create(:user, id: 2) }
    let(:user_odd) { create(:user, id: 3) }

    context "NEW_UI=all の場合" do
      before { allow(ENV).to receive(:[]).with("NEW_UI").and_return("all") }

      it "全員に新UIを表示" do
        expect(Features.new_ui_enabled?(user_even)).to be true
        expect(Features.new_ui_enabled?(user_odd)).to be true
      end
    end

    context "NEW_UI=test の場合" do
      before { allow(ENV).to receive(:[]).with("NEW_UI").and_return("test") }

      it "偶数IDのユーザーのみ新UI" do
        expect(Features.new_ui_enabled?(user_even)).to be true
        expect(Features.new_ui_enabled?(user_odd)).to be false
      end
    end

    context "NEW_UI未設定の場合" do
      before { allow(ENV).to receive(:[]).with("NEW_UI").and_return(nil) }

      it "全員旧UI" do
        expect(Features.new_ui_enabled?(user_even)).to be false
        expect(Features.new_ui_enabled?(user_odd)).to be false
      end
    end
  end
end
```

**解説:**
- `case`文で環境変数の値を分岐
- A/Bテストでは偶数IDと奇数IDで分割（シンプルな実装）
- テストでは3パターンすべてをカバー

</details>

---

### 問題3: 削除容易性を確保した設計の練習

以下のコードを、フィーチャーフラグパターンを使って「削除容易性」を確保した設計に書き換えてください。

**現在のコード（アンチパターン）:**

```ruby
# app/models/user.rb
class User < ApplicationRecord
  def premium?
    # 将来的には課金機能を実装予定だが、現在は管理者のみpremium
    admin?
  end
end

# app/controllers/application_controller.rb
def require_premium!
  redirect_to root_path, alert: "プレミアム会員限定機能です" unless current_user.premium?
end

# app/views/lessons/index.html.slim
- @lessons.each do |lesson|
  .lesson
    h2= lesson.title
    - if lesson.premium? && !current_user.premium?
      span.badge プレミアム限定
    - else
      = link_to "レッスンを開始", lesson_path(lesson)
```

**要件:**
- フィーチャーフラグ `PREMIUM_FEATURE` を導入（デフォルト: `false`）
- フィーチャーフラグがOFFの場合、全員がpremium扱い
- 将来的に課金機能実装時は、フィーチャーフラグをONに切り替え

<details>
<summary>解答例を表示</summary>

**1. フィーチャーフラグ初期化ファイル**

```ruby
# config/initializers/features.rb
module Features
  # プレミアム機能を有効にするかどうか
  #
  # @return [Boolean] プレミアム機能が有効な場合true
  #
  # NOTE: 課金機能実装後に true に切り替える予定
  # NOTE: 現在は false（全員がプレミアム扱い）
  def self.premium_feature_enabled?
    ENV.fetch("PREMIUM_FEATURE", "false") == "true"
  end
end
```

**2. モデル変更**

```ruby
# app/models/user.rb
class User < ApplicationRecord
  # プレミアム会員かどうか
  #
  # @return [Boolean] プレミアム会員の場合true
  #
  # 🔑 将来的に削除予定（課金機能実装後は subscription テーブルで判定）
  def premium?
    # プレミアム機能が無効なら全員premium
    return true unless Features.premium_feature_enabled?

    # プレミアム機能が有効な場合、管理者のみpremium
    # TODO: 課金機能実装後は subscription.active? で判定
    admin?
  end
end
```

**3. コントローラー変更（変更なし）**

```ruby
# app/controllers/application_controller.rb
def require_premium!
  redirect_to root_path, alert: "プレミアム会員限定機能です" unless current_user.premium?
end
```

**4. ビュー変更（変更なし）**

```slim
/ app/views/lessons/index.html.slim
- @lessons.each do |lesson|
  .lesson
    h2= lesson.title
    - if lesson.premium? && !current_user.premium?
      span.badge プレミアム限定
    - else
      = link_to "レッスンを開始", lesson_path(lesson)
```

**解説:**

**削除容易性のポイント:**
1. フィーチャーフラグを1箇所に集約（`config/initializers/features.rb`）
2. 🔑 絵文字でマーキング（削除対象を明確化）
3. コメントで将来の移行計画を記載（TODOコメント）
4. コントローラーとビューは変更不要（モデルのみ変更）

**将来の移行手順:**

**Phase 1: 課金機能実装**

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_subscriptions.rb
class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.boolean :active, default: false, null: false
      t.datetime :expires_at
      t.timestamps
    end
  end
end

# app/models/user.rb
class User < ApplicationRecord
  has_one :subscription

  def premium?
    # プレミアム機能が無効なら全員premium
    return true unless Features.premium_feature_enabled?

    # subscription テーブルで判定
    subscription&.active? || admin?
  end
end
```

**Phase 2: フィーチャーフラグをON（環境変数変更のみ）**

```bash
# .kamal/secrets
PREMIUM_FEATURE=true
```

**Phase 3: 様子見期間（1-2週間）**

問題がないことを確認。

**Phase 4: フィーチャーフラグ削除**

```ruby
# config/initializers/features.rb
# ⇒ ファイル削除（または premium_feature_enabled? メソッドのみ削除）

# app/models/user.rb
def premium?
  subscription&.active? || admin?
end
```

**削減効果:**
- フィーチャーフラグパターンにより、段階的な移行が可能
- 問題発生時は `PREMIUM_FEATURE=false` に戻すだけで復旧
- コントローラーとビューは一切変更不要（モデルのみ変更）

</details>

---

**作成日**: 2026-01-03
**難易度**: 🟡 中級
**推定学習時間**: 1〜2時間
