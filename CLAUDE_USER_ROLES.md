# ユーザーロールとサブスクリプション設計

## 📋 概要

Typnixにおけるユーザーのロールとサブスクリプション状態の設計ドキュメント。
タイピング練習アプリの特性を活かした「卒業」システムを含む、柔軟な権限管理を実現する。

---

## 🎯 設計方針

### 基本原則

1. **2軸管理**: 管理者権限とサブスク状態を分離
2. **関心の分離**: 異なる概念を異なるカラムで管理
3. **柔軟性**: 将来の拡張に対応可能
4. **既存コードとの互換性**: 現在の`admin`カラムを活用

### 2つの軸

#### A. 管理者権限軸
- `admin` (boolean): 管理者フラグ
- 開発者と公式アカウントが該当

#### B. サブスクリプション状態軸
- `subscription_status` (enum): 課金・機能利用状態
- 一般、プレミアム、卒業生、テスターを管理

---

## 🗂 データ構造

### Userモデルのカラム構成

```ruby
class User < ApplicationRecord
  # 既存カラム
  # admin: boolean (デフォルト: false)

  # 新規追加カラム
  # subscription_status: integer (デフォルト: 0 = free)

  enum subscription_status: {
    free: 0,           # 一般ユーザー（デフォルト）
    premium: 10,       # プレミアムユーザー（課金中）
    graduated: 20,     # 卒業生（課金停止、機能は継続利用可）
    tester: 30         # テスター（無料で有料機能を試用）
  }, _prefix: true
end
```

### マイグレーション

```ruby
class AddSubscriptionStatusToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :subscription_status, :integer, default: 0, null: false
    add_index :users, :subscription_status

    # 既存ユーザーは全員 free に設定（デフォルト値で自動設定される）
  end
end
```

---

## 👥 ユーザー種別一覧

| ユーザー種別 | admin | subscription_status | 有料機能 | 課金 | 説明 |
|------------|-------|---------------------|---------|------|------|
| **非ログイン者** | - | - | ❌ | ❌ | お試し利用。Userレコードなし |
| **一般ユーザー** | false | `free` | ❌ | ❌ | ログイン済み。記録・キーマップ登録可能 |
| **プレミアムユーザー** | false | `premium` | ✅ | ✅ | 課金中。全機能利用可能 |
| **卒業生** | false | `graduated` | ✅ | ❌ | 卒業試験合格。課金停止、機能は継続利用可 |
| **テスター** | false | `tester` | ✅ | ❌ | ベータテスター。無料で有料機能を試用 |
| **管理者/公式** | true | (任意) | ✅ | - | 開発者・公式アカウント。全権限 |

---

## 🔑 権限判定メソッド

### 基本メソッド

```ruby
class User < ApplicationRecord
  # 有料機能が使えるか
  def has_premium_features?
    subscription_status_premium? ||
    subscription_status_graduated? ||
    subscription_status_tester?
  end

  # 現在課金中か（Stripe連携用）
  def paying_subscriber?
    subscription_status_premium?
  end

  # 公式アカウントか
  def official?
    admin
  end

  # 既存のpremium?メソッドとの互換性
  def premium?
    has_premium_features?
  end
end
```

### 権限チェック例

```ruby
# コントローラーでの使用例
class My::LessonsController < ApplicationController
  before_action :require_premium_features

  private

  def require_premium_features
    unless current_user.has_premium_features?
      redirect_to root_path, alert: "この機能はプレミアムユーザー限定です。"
    end
  end
end
```

---

## 🎓 卒業システム設計

### コンセプト

タイピング練習アプリの特性上、「上達したらアプリを必要としなくなる」というジレンマを解決。
**「受講→卒業」** という流れで、ユーザーの成長をポジティブに捉える。

### 卒業の条件

```ruby
class User < ApplicationRecord
  def meets_graduation_criteria?
    # 以下すべてを満たす必要がある
    premium_months >= 3 &&                    # 1. 連続3ヶ月以上の課金
      lesson_records.count >= 100 &&          # 2. 累計100レッスン以上完了
      average_wpm >= 60 &&                    # 3. 平均WPM 60以上
      average_accuracy >= 90                  # 4. 平均正答率 90%以上
  end

  def can_graduate?
    # 卒業試験を受けられるか
    subscription_status_premium? && meets_graduation_criteria?
  end

  def premium_months
    # Subscriptionモデルから計算（将来実装）
    # または subscription_started_at カラムを追加
    return 0 unless subscription_status_premium?

    # 実装例（将来）
    # (Time.current - subscription_started_at).to_i / 1.month
  end

  def average_wpm
    lesson_records.average(:wpm)&.to_f || 0
  end

  def average_accuracy
    lesson_records.average(:accuracy)&.to_f || 0
  end
end
```

### 卒業試験フロー

#### 1. 卒業試験ページ (`/my/graduation`)

```slim
/ 条件達成状況を表示
.graduation-status
  h2 卒業条件の達成状況

  .criteria
    .item class=(@user.premium_months >= 3 ? 'completed' : 'pending')
      | 課金期間: #{@user.premium_months}ヶ月 / 3ヶ月以上

    .item class=(@user.lesson_records.count >= 100 ? 'completed' : 'pending')
      | レッスン完了数: #{@user.lesson_records.count} / 100以上

    .item class=(@user.average_wpm >= 60 ? 'completed' : 'pending')
      | 平均WPM: #{@user.average_wpm.round(1)} / 60以上

    .item class=(@user.average_accuracy >= 90 ? 'completed' : 'pending')
      | 平均正答率: #{@user.average_accuracy.round(1)}% / 90%以上

  - if @user.can_graduate?
    = link_to "卒業試験を受ける", new_my_graduation_exam_path, class: "btn-primary"
  - else
    p.text-muted すべての条件を満たすと卒業試験を受けられます
```

#### 2. 試験内容

- **特別な難易度のレッスンを3つ連続クリア**
- **各レッスンで WPM 70以上、正答率 95%以上** が必要
- 1つでも基準を満たさない場合は不合格（再挑戦可能）

#### 3. 合格後の処理

```ruby
class My::GraduationExamsController < ApplicationController
  def complete
    @exam = current_user.graduation_exams.find(params[:id])

    if @exam.passed?
      # ステータスを卒業生に変更
      current_user.update!(subscription_status: :graduated)

      # Stripeのサブスクをキャンセル（将来実装）
      # current_user.subscription.cancel!

      # 卒業証明書発行
      @exam.update!(certificate_issued_at: Time.current)

      redirect_to my_graduation_path, notice: "おめでとうございます！卒業試験に合格しました！"
    else
      redirect_to my_graduation_exam_path(@exam), alert: "残念ながら不合格でした。再挑戦してください。"
    end
  end
end
```

### 卒業生の特典

- ✅ **有料機能の継続利用**: キーマップ公開、レッスン作成・公開など
- ✅ **卒業証明書バッジ**: プロフィールに表示
- ✅ **課金停止**: サブスクリプション自動解約
- ✅ **名誉ある称号**: 「Typnix卒業生」バッジ

---

## 🎯 有料機能一覧（案）

### プレミアム/卒業生/テスターが利用可能

| 機能 | 説明 | 実装優先度 |
|------|------|-----------|
| **キーマップ公開** | 自分のキーマップを他ユーザーに公開 | Phase 2 |
| **レッスン作成・公開** | オリジナルレッスンを作成・公開 | Phase 2 |
| **特別なバッジ** | プロフィールにプレミアムバッジ表示 | Phase 1 |
| **統計グラフ** | 正答率・WPMの推移グラフ | Phase 3 |
| **高度なフィルター** | 練習履歴の詳細フィルタリング | Phase 3 |
| **広告非表示** | AdSense広告を非表示 | Phase 1 |

### 一般ユーザーも利用可能（無料機能）

| 機能 | 説明 |
|------|------|
| **練習履歴記録** | 無制限に記録保存 |
| **キーマップ登録** | 最大2つまで登録可能 |
| **公式レッスン** | 基礎カテゴリのレッスン |
| **自作レッスン** | 最大2つまで作成可能（非公開のみ） |

---

## 📅 実装フェーズ

### Phase 1: 基盤整備（現在）

- [x] `admin` カラム実装済み
- [ ] `subscription_status` enum追加
- [ ] 権限判定メソッド実装
- [ ] 既存コードの移行（`premium?`メソッド）
- [ ] テスター向けフラグ設定（ALLOWED_EMAILSとは別管理）

### Phase 2: プレミアム機能実装

- [ ] キーマップ公開機能
- [ ] レッスン作成・公開機能
- [ ] プレミアムバッジ表示
- [ ] 機能制限の実装（一般ユーザー vs プレミアム）

### Phase 3: Stripe統合

- [ ] `Subscription` モデル作成
- [ ] Stripe Checkout統合
- [ ] Webhook処理（支払い成功/失敗）
- [ ] `premium` ↔ `free` の自動切り替え
- [ ] サブスク管理ページ（`/my/subscription`）

### Phase 4: 卒業システム実装

- [ ] `GraduationExam` モデル作成
- [ ] 卒業条件判定ロジック
- [ ] 卒業試験ページ（`/my/graduation`）
- [ ] 卒業試験実施機能
- [ ] 卒業証明書バッジ
- [ ] Stripeサブスク自動キャンセル

---

## 🗃️ 将来のテーブル設計

### GraduationExamモデル

```ruby
class GraduationExam < ApplicationRecord
  belongs_to :user
  has_many :graduation_exam_records, dependent: :destroy

  enum status: {
    pending: 0,    # 試験中
    passed: 10,    # 合格
    failed: 20     # 不合格
  }

  # attempted_at: datetime          # 試験開始日時
  # completed_at: datetime           # 試験完了日時
  # certificate_issued_at: datetime  # 卒業証明書発行日時
  # status: integer                  # ステータス
end

class GraduationExamRecord < ApplicationRecord
  belongs_to :graduation_exam
  belongs_to :lesson

  # wpm: float                       # WPM
  # accuracy: float                  # 正答率
  # passed: boolean                  # この試験はパスしたか
  # completed_at: datetime           # 完了日時
end
```

### Subscriptionモデル（Stripe連携）

```ruby
class Subscription < ApplicationRecord
  belongs_to :user

  enum status: {
    active: 0,      # 有効
    canceled: 10,   # キャンセル済み
    past_due: 20    # 支払い遅延
  }

  # stripe_subscription_id: string   # StripeのサブスクID
  # stripe_customer_id: string       # StripeのカスタマーID
  # status: integer                  # ステータス
  # current_period_start: datetime   # 現在の課金期間開始
  # current_period_end: datetime     # 現在の課金期間終了
  # canceled_at: datetime            # キャンセル日時
end
```

---

## 🔄 状態遷移図

```
[非ログイン者]
    ↓ Googleログイン
[一般ユーザー (free)]
    ↓ 課金開始
[プレミアムユーザー (premium)]
    ↓ 卒業試験合格
[卒業生 (graduated)]

※ テスター (tester) は管理者が手動で設定
```

### 状態遷移パターン

1. **通常の課金フロー**
   - `free` → `premium` (Stripe課金成功)
   - `premium` → `free` (サブスクキャンセル)

2. **卒業フロー**
   - `premium` → `graduated` (卒業試験合格)
   - `graduated` → `premium` (再課金、稀なケース)

3. **テスターフロー**
   - `free` → `tester` (管理者が手動設定)
   - `tester` → `free` (テスト期間終了)
   - `tester` → `premium` (正式課金)

---

## 💡 将来の拡張アイデア

### 複数プランの対応

現在は単一のプレミアムプランだが、将来的に複数プラン対応も可能：

```ruby
enum subscription_plan: {
  free: 0,
  basic: 10,      # 月額500円
  standard: 20,   # 月額1000円
  pro: 30         # 月額2000円
}

def has_premium_features?
  subscription_plan_basic? ||
  subscription_plan_standard? ||
  subscription_plan_pro? ||
  subscription_status_graduated? ||
  subscription_status_tester?
end
```

### 卒業生の再挑戦制度

- 一定期間後、卒業生が「再受講→再卒業」できる仕組み
- より高度なスキル証明

### 企業向けプラン

- チーム単位でのサブスクリプション
- 管理者による社員の進捗管理

---

## 📝 命名について

### subscription_status の値

| enum値 | 日本語名 | 英語の意味 |
|--------|---------|-----------|
| `free` | 一般ユーザー | 無料 |
| `premium` | プレミアムユーザー | 有料会員 |
| `graduated` | 卒業生 | 卒業した |
| `tester` | テスター | ベータテスター |

### 代替案（検討済み）

- **卒業生の英語名**:
  - `graduated` ✅（採用: 分かりやすい）
  - `alumni` （大学の卒業生っぽい）
  - `lifetime` （生涯利用権っぽい）
  - `emeritus` （名誉教授っぽい）

---

## 🚨 注意事項

### セキュリティ

- `admin`フラグは絶対に改ざんされないよう、Strong Parametersで保護
- サブスク状態の変更はStripe Webhookまたは管理者のみ

### データ整合性

- `subscription_status`の変更履歴を残す（将来的に`SubscriptionHistory`テーブル追加検討）
- Stripeとの同期ズレを防ぐため、Webhook処理を確実に

### ユーザー体験

- 課金→卒業の流れは「成功体験」として演出
- 卒業試験は難しすぎず、達成感のあるバランス

---

## 📚 関連ドキュメント

- `CLAUDE_FEATURES.md` - 実装済み機能一覧
- `CLAUDE_LESSON_DB_PLAN.md` - レッスンDB化と課金設計
- `CLAUDE.md` - プロジェクト全体設計

---

**最終更新**: Day 26（2025-12-26）
**ステータス**: 設計完了、実装は Phase 1 から順次進行予定
