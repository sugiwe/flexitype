# ホワイトリスト管理機能の設計検討

## 概要

ベータ版の運用において、ログイン許可リスト（ALLOWED_EMAILS）への追加作業を効率化するための機能検討。

現状は環境変数で管理しているが、管理画面から直接追加できるようにしたい。

**検討日**: 2025-12-20
**ステータス**: 保留（実装時期未定）

---

## 現状の課題

- ログイン許可リストは環境変数 `ALLOWED_EMAILS` で管理（カンマ区切り）
- 新規ユーザーを追加するには：
  1. `.kamal/secrets` ファイルを手動編集
  2. Kamalで再デプロイ
  3. 数分のダウンタイムが発生
- ベータテスト申し込みが増えると運用負荷が高い

---

## 検討した3つのアプローチ

### アプローチ1: Googleフォーム連携 + 承認ワークフロー

#### 概要
Googleフォームで申し込みを受付 → Google Sheets API経由でRailsに取り込み → 管理画面で承認

#### 技術的な実装方法
- Google Sheets APIを使って回答を取得
- `google-api-ruby-client` gem
- PendingUser モデル（申請待ちユーザー）
- バックグラウンドジョブでポーリング（5分ごと）またはWebhook

#### メリット
- ✅ ユーザーが使い慣れたGoogleフォームで申請できる
- ✅ フォームのデザイン・質問項目を簡単にカスタマイズ可能
- ✅ スパム対策（reCAPTCHA）が標準装備
- ✅ 申請理由などの情報も同時に収集可能

#### デメリット
- ❌ 実装が複雑（Google API認証、ポーリング処理、エラーハンドリング）
- ❌ Google Sheets APIの利用制限（1分あたり100リクエストなど）
- ❌ 認証情報の管理が必要（サービスアカウントJSONなど）
- ❌ デバッグが難しい（外部API依存）
- ❌ ポーリング間隔によってはリアルタイム性に欠ける

#### セキュリティリスク
- Google APIの認証情報漏洩リスク
- Sheets APIの権限設定ミスによるデータ漏洩

#### 実装時間
**1日〜1.5日**

---

### アプローチ2-A: 環境変数ファイル更新方式

#### 概要
管理画面からメールアドレスを入力 → `.kamal/secrets` ファイルを直接更新 → 再デプロイ

#### メリット
- ✅ 既存の仕組み（ALLOWED_EMAILS環境変数）をそのまま使える
- ✅ 実装が非常にシンプル
- ✅ DB不要

#### デメリット
- ❌ ファイル書き込み権限が必要（セキュリティリスク）
- ❌ 再デプロイが必要（数分のダウンタイム）
- ❌ Gitにコミットするかどうかの判断が必要
- ❌ 並行編集時の競合リスク

#### セキュリティリスク
- ⚠️ **Railsプロセスからファイルシステムへの書き込みを許可するのは危険**
- ⚠️ `.kamal/secrets`が誤って公開リポジトリにコミットされるリスク

#### 実装時間
**2〜3時間**

#### 評価
**セキュリティリスクが高いため非推奨**

---

### アプローチ2-B: DB管理 + 環境変数併用（推奨）

#### 概要
`AllowedEmail` モデルをDBで管理 + 環境変数も併用（開発者専用）

#### データモデル設計

```ruby
# app/models/allowed_email.rb
class AllowedEmail < ApplicationRecord
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  before_validation :downcase_email

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
```

**マイグレーション:**
```ruby
class CreateAllowedEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :allowed_emails do |t|
      t.string :email, null: false, limit: 254
      t.text :note, limit: 500  # 申請理由などのメモ
      t.timestamps
    end

    add_index :allowed_emails, :email, unique: true
  end
end
```

#### 認証ロジックの更新

```ruby
# app/models/user.rb
def self.email_allowed?(email)
  return false if email.blank?

  normalized_email = email.downcase.strip

  # 環境変数のチェック（開発者専用）
  env_allowed = ENV["ALLOWED_EMAILS"]&.split(",")&.map(&:strip)&.map(&:downcase) || []
  return true if env_allowed.include?(normalized_email)

  # DBのチェック（運用で追加）
  AllowedEmail.exists?(email: normalized_email)
end
```

#### 管理画面UI

```ruby
# app/controllers/admin/allowed_emails_controller.rb
class Admin::AllowedEmailsController < Admin::ApplicationController
  def index
    @allowed_emails = AllowedEmail.order(created_at: :desc).page(params[:page]).per(20)
  end

  def create
    @allowed_email = AllowedEmail.new(allowed_email_params)
    if @allowed_email.save
      redirect_to admin_allowed_emails_path, notice: "#{@allowed_email.email} をホワイトリストに追加しました"
    else
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @allowed_email = AllowedEmail.find(params[:id])
    @allowed_email.destroy
    redirect_to admin_allowed_emails_path, notice: "#{@allowed_email.email} をホワイトリストから削除しました"
  end

  private

  def allowed_email_params
    params.require(:allowed_email).permit(:email, :note)
  end
end
```

#### メリット
- ✅ 実装がシンプル（標準的なRails CRUD）
- ✅ 即座に反映（再デプロイ不要）
- ✅ 管理画面で一覧・追加・削除が可能
- ✅ 申請理由などのメモを記録可能
- ✅ セキュリティリスクが低い（DB操作のみ）
- ✅ 環境変数との併用で開発者権限を分離

#### デメリット
- ⚠️ DBテーブルが1つ増える（運用コスト）
- ⚠️ バックアップ時にAllowedEmailテーブルも含める必要

#### セキュリティ考慮
- ✅ 管理者のみアクセス可能（既存のAdmin::ApplicationController）
- ✅ Strong Parameters
- ✅ CSRF保護（Rails標準）
- ✅ SQLインジェクション対策（ActiveRecord）
- ✅ メールアドレスのバリデーション

#### 実装時間
**3〜4時間**

---

## 推奨アプローチ

### 🎯 アプローチ2-B（DB管理 + 環境変数併用）を推奨

#### 理由

1. **実装の複雑さとROIのバランスが最適**
   - Googleフォーム連携は過剰設計（ベータ版の規模には不要）
   - 環境変数ファイル更新は危険
   - DB管理は標準的で安全

2. **セキュリティ**
   - ファイルシステムへの書き込みを避けられる
   - Google API認証情報の管理が不要
   - Rails標準のセキュリティ機能で十分

3. **運用の利便性**
   - 管理画面から即座に追加・削除可能
   - 再デプロイ不要
   - 申請理由などのメモを残せる

4. **拡張性**
   - 将来的にユーザー申請フォームを追加可能（PendingUserテーブル）
   - 承認ワークフローへの拡張も容易

5. **メンテナンス性**
   - 標準的なRails CRUD実装
   - デバッグが容易
   - コードの見通しが良い

---

## 将来的な拡張パス（オプション）

アプローチ2-Bを実装した後、必要に応じて段階的に拡張できます：

### Phase 1: DB管理の基盤実装（推奨）
- AllowedEmailモデル
- 管理画面CRUD UI

### Phase 2: ユーザー申請フォーム（将来）
- `/apply` ページを作成
- PendingUserモデル（申請待ちユーザー）
- 管理画面に承認UI

### Phase 3: Googleフォーム連携（任意）
- 必要性が高まった場合のみ実装
- Phase 2の基盤を活用

---

## 実装計画（Phase 1の場合）

### 実装内容

1. `feature/whitelist-management` ブランチ作成
2. AllowedEmailモデル作成（マイグレーション、バリデーション）
3. User.email_allowed? メソッド更新
4. Admin::AllowedEmailsController実装
5. 管理画面UI実装（一覧、追加フォーム、削除ボタン）
6. テスト（ローカル環境）
7. RuboCop + Brakeman チェック
8. コミット → PR作成 → 本番デプロイ

### 所要時間
**3〜4時間**

---

## 備考

- この機能は一旦保留とする（2025-12-20時点）
- 実装するタイミングが来たら、このドキュメントを参照して進める
- ベータ版の規模が拡大し、運用負荷が高まった時点で再検討
