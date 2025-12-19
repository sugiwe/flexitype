# 実装済み機能の詳細仕様

**最終更新**: 2025-12-20（Day 20完了時点）

このドキュメントには、Typnixアプリで実装済みの全機能の詳細仕様を記載しています。
新しい機能を実装した際は、このドキュメントを随時更新してください。

---

## 1. ユーザー認証（✅ Day 3完了）

### 概要
- Google Identity Services を使用したログイン機能
- メール許可リスト制によるベータ版アクセス制御
- セッション管理でログイン状態を保持

### 認証フロー
1. フロントエンドで Google Identity Services を使用して ID トークンを取得
2. ID トークンを Rails サーバーに送信（POST `/auth/google`）
3. サーバー側で ID トークンを検証（`google-id-token` gem）
4. メール許可リストをチェック（環境変数 `ALLOWED_EMAILS`）
5. ユーザーを作成またはログイン処理

### User モデル

```ruby
# カラム
- google_uid (string, unique, not null, indexed)
- email (string, unique, not null, max: 254)
- name (string, not null, max: 30)
- icon_url (string, max: 4096)
- username (string, unique, max: 30) ← Day 17で追加
- history_limit (integer, default: 50, not null)
- last_sign_in_at (datetime, indexed) ← Day 20で追加
- current_sign_in_at (datetime) ← Day 20で追加
- sign_in_count (integer, default: 0, not null) ← Day 20で追加

# アソシエーション
- has_many :keymap_sets, dependent: :destroy
- has_many :typing_sessions, dependent: :destroy

# クラスメソッド
- from_google(payload): Google認証からユーザーを作成/取得
- email_allowed?(email): メール許可リストチェック

# インスタンスメソッド
- cleanup_old_typing_sessions: 古い履歴を削除
```

### セキュリティ
- CSRF トークン検証
- ID トークンの署名検証
- メール許可リスト（環境変数管理）
- Strong Parameters

---

## 2. キーマップ管理（✅ Day 18完了、Phase 1）

### 概要
- デフォルトキーマップ + ユーザーカスタマイズ
- 複数キーマップ管理（KeymapSet）
- slug ベースのURL（`/my/keymaps/:slug/edit`）
- 6レイヤー対応（Layer 0-5）

### デフォルトキーマップとカスタマイズ
- **ログアウト状態でもタイピング練習可能**: デフォルトキーマップで動作
- **キーマップ未設定ユーザーもデフォルトで使える**: 初期状態でもすぐに練習開始できる
- **ログイン後にカスタマイズ可能**: 自分専用のキーマップを登録・保存できる

### 物理配列
- Cornix 固定（6列×3-4行、左右分割）
- 将来的に他のキーボードに対応する可能性も考慮した設計（`CLAUDE_KEYBOARD_TYPE_DESIGN.md`参照）

### KeymapSet モデル（Day 18で実装）

```ruby
# カラム
- user_id (references users, not null)
- name (string, max: 50, not null)
- slug (string, max: 50, not null, indexed)
- description (text, max: 500, nullable)
- is_public (boolean, default: false, not null)
- forked_from_id (integer, nullable)
- keyboard_type (string, default: "split_ortho_4x6", not null)
- created_at, updated_at

# アソシエーション
- belongs_to :user
- has_many :keymaps, dependent: :destroy

# バリデーション
- validates :name, presence: true, length: { maximum: 50 }
- validates :slug, presence: true, uniqueness: { scope: :user_id }
- validates :description, length: { maximum: 500 }, allow_blank: true

# スコープ
- scope :published, -> { where(is_public: true) }
```

### Keymap モデル（既存を拡張）

```ruby
# カラム
- user_id (references users, not null)
- keymap_set_id (references keymap_sets, not null) ← Day 18で追加
- layer (integer, 0-5, not null)
- key_position (string, 例: "L0-R0", not null)
- character (string, max: 20, not null)
- created_at, updated_at

# インデックス
- [user_id, layer, key_position], unique: true
- [keymap_set_id, layer, key_position], unique: true

# クラスメソッド
- for_user_layer(user_id, layer): 特定レイヤーのキーマップをハッシュで取得
- bulk_upsert(user_id, layer, keymap_hash): キーマップの一括更新
```

### 登録UI（2段階選択方式）
1. **上側**: 物理キーボード配列（登録先を選択）
2. **下側**: 入力候補ボタン（登録元を選択）

**入力候補の整理:**
- 文字・数字タブ: アルファベット（A/a）、数字・記号ペア（!/1）
- 記号・特殊キータブ: 記号ペア（_/-）、特殊キー（Space, Enter など）、矢印キー、Fn + F1-F12
- 2段表示で Shift ペアを表現（デリミタ: `|`）

### URL設計
- `/my/keymaps` - キーマップ一覧
- `/my/keymaps/:slug/edit` - キーマップ編集

### 将来的な拡張
- Phase 2: 複数キーマップ対応（無課金2つ、課金5つまで）
- Phase 3: 公開・共有機能、フォーク機能
- 詳細: `CLAUDE_KEYMAP_EXPANSION.md`

---

## 3. タイピング練習（✅ Day 9完了）

### レッスンシステム
- **10カテゴリ、20+レッスン** を用意
- カテゴリ: 単語練習、文章練習、記号練習、プログラミング、日本語入力など
- YAML ファイルで管理（`config/lessons/`）
- LessonLoader サービスクラスでレッスン情報と練習項目を取得

### 練習フロー
1. 画面上に1単語ずつ表示
2. キー入力ごとに正誤を判定
3. BackSpace で修正可能
4. 正しい入力が完了したら次の単語へ
5. 1セッション = 20単語（レッスンにより異なる）
6. セッション完了画面で統計表示（正答率、所要時間、ミス数）

### 判定ロジック
- 入力文字と正解文字を1文字ずつ比較
- 間違えた文字は入力をロック（BackSpace で修正）
- 正しい入力後、次の文字へフォーカス移動

### キーボード表示・ガイド機能

#### 描画方法
- CSS Grid + margin 調整でカラムスタッガードを再現
- 将来的に SVG 化も検討

#### ハイライト機能
- 次に打つべきキーをリアルタイムでハイライト
- レイヤー切り替えが必要な場合:
  - レイヤーボタン（例: 左親指） + 目的の文字キーの2箇所を同時にハイライト
  - 例: "1" を打つ場合 → レイヤー1ボタン + レイヤー1の"1"の位置

#### 指ガイド機能
- **指ごとの色分け:**
  - 小指（左右）: 赤色（`bg-red-100` / `bg-red-300`）
  - 薬指（左右）: 黄色（`bg-yellow-100` / `bg-yellow-300`）
  - 中指（左右）: 青色（`bg-blue-100` / `bg-blue-300`）
  - 人差し指（左右）: 緑色（`bg-green-100` / `bg-green-300`）
  - 親指（左右）: グレー（`bg-gray-100` / `bg-gray-300`）
- **キーの色付け:**
  - 各キーに指ごとの薄い色を常時表示
  - 次に打つべきキーは、その指の色が濃くなる
  - リングエフェクト（`ring-2`）で控えめに強調
- **指ガイド表示:**
  - キーボード下部に左右それぞれ5本指のガイドを表示
  - 各指に「小・薬・中・人・親」のラベル
  - 次に使う指のガイドも濃い色に変化
  - 指ごとに異なる高さ（手の形を模した表示）

#### レイヤー自動判定
- アプリが次に打つ文字を解析
- ユーザーのキーマップから「どのレイヤーに配置されているか」を自動判定
- 該当レイヤーのキーマップ表示に自動切り替え
- Layer 0を最優先として検索し、全6レイヤーから文字を検索
- レイヤーボタン + 目的の文字キーの2箇所を同時にハイライト

#### 2段表示機能
- キーに2段表示（通常時|Shift時）を表示
- デリミタ: `|`（例: `Q|q`, `!|1`, `?|/`）
- Ruby版（ApplicationHelper）とJavaScript版（typing_controller.js）で統一実装
- 特殊キー（Spc, BS, Ent, Lyr1など）は1段表示

---

## 4. 練習履歴・統計（✅ Day 16完了）

### 概要
- ログインユーザー向け機能
- 無料ユーザーは50件の履歴を保持（自動クリーンアップ）
- 将来の課金ユーザー向けに拡張可能な設計

### TypingSession モデル

```ruby
# カラム
- user_id (references users, not null)
- category (string)
- lesson_id (string)
- lesson_name (string)
- word_count (integer, default: 0, not null)
- correct_count (integer, default: 0, not null)
- mistake_count (integer, default: 0, not null)
- accuracy (decimal, precision: 5, scale: 2)
- duration_seconds (integer)
- completed_at (datetime)
- created_at, updated_at

# インデックス
- [user_id, completed_at], order: { completed_at: :desc }
- [user_id, created_at], order: { created_at: :desc }

# スコープ
- recent: order(completed_at: :desc)

# コールバック
- after_create :cleanup_old_sessions
```

### 自動クリーンアップ
- TypingSession作成後、after_createコールバックで実行
- history_limitを超えた古い履歴を自動削除
- パフォーマンスを考慮したインデックス設計

### 履歴一覧ページ（`/my/history`）
- **レスポンシブUI**
  - PC: テーブル形式（日時、レッスン、単語数、正答率、所要時間、ミス数）
  - モバイル: カード形式（同じ情報をコンパクトに表示）
- **ミニ統計**
  - 総練習回数（青色アイコン）
  - 平均正答率（緑色アイコン）
- **正答率の色分け**
  - 90%以上: 緑色
  - 70%以上: 黄色
  - それ以下: 赤色
- **ページネーション**: Kaminari gem、1ページ20件
- **空状態UI**: 履歴なし時の誘導メッセージ

### 自動保存機能
- タイピング練習終了時に自動的に履歴を保存
- typing_controller.js で JSON API を呼び出し（POST `/history`）
- ログインユーザーのみ保存（loggedInValueで判定）
- CSRF対策、エラーハンドリング

### 将来の拡張
- 統計グラフ（正答率の推移など）
- 詳細な統計ページ（`/my/history/stats`）
- WPM（Words Per Minute）の記録

---

## 5. 管理者ダッシュボード（✅ Day 20完了）

### 概要
- ベータテストユーザーの活動状況を開発者が監視
- ユーザー数、練習回数、キーマップ数などの統計情報をダッシュボードで一覧表示
- 個別のユーザー詳細ページで、各ユーザーの練習履歴やキーマップを確認

### アクセス制御
- 開発者（管理者）のみアクセス可能
- 環境変数 `ADMIN_EMAILS` でメールアドレスをカンマ区切りで管理
- `Admin::ApplicationController` で `before_action :require_admin!` を実装
- `admin?` ヘルパーメソッドでサイドバーメニューの表示制御

### URL構造
- `GET /admin` - 管理者ダッシュボード（統計概要 + ユーザー一覧）
- `GET /admin/users` - ユーザー一覧（ページネーション付き）
- `GET /admin/users/:id` - ユーザー詳細（練習履歴、キーマップ、詳細統計）

### ダッシュボード構成要素
1. **統計サマリーカード（4つ）**
   - 総ユーザー数（青色、サブテキスト: 今週の新規登録）
   - 総練習回数（緑色、サブテキスト: 今日の練習）
   - 総キーマップ数（黄色、サブテキスト: 公開キーマップ）
   - 総レッスン数（紫色、サブテキスト: カテゴリー数）

2. **アクティブユーザー統計**
   - 過去7日間のアクティブユーザー数
   - 過去30日間のアクティブユーザー数
   - 今週の練習回数

3. **最新ユーザー（10名）**
   - 最終ログイン日時の降順
   - アバター、名前、ユーザー名、メール、練習回数、キーマップ数、最終ログイン

4. **最新練習履歴（10件）**
   - 完了日時の降順
   - ユーザー名、レッスン名、正答率、所要時間、ミス数
   - N+1クエリ対策（`includes(:user)`）

5. **レッスンカテゴリー統計**
   - 各カテゴリーのレッスン数

6. **人気レッスンランキング（TOP 10）**
   - レッスン名、総練習回数、平均正答率
   - SQL GROUP BY集計

### ログイン追跡機能
- `last_sign_in_at`, `current_sign_in_at`, `sign_in_count` カラムをUserモデルに追加
- SessionsController#createでログイン情報を更新

### 詳細設計
- `CLAUDE_ADMIN_DASHBOARD.md` に完全な設計ドキュメントを記載

---

## 6. レスポンシブ対応（✅ Day 15完了）

### 概要
- モバイル・PC両対応
- ブレークポイント: 768px（Tailwind CSS の `md:`）

### レイアウト

**PC（768px以上）:**
- 左固定サイドバー（300px）
  - ロゴエリア
  - ナビゲーションメニュー
  - 広告スペース（300x250px）
  - ユーザー情報・認証エリア
- 右メインコンテンツ（可変幅）

**モバイル（768px未満）:**
- ハンバーガーメニュー方式
- サイドバーは画面外に隠れる
- メニューアイコンクリックで表示
- オーバーレイとスムーズなアニメーション
- 100dvh を使用してモバイルブラウザのアドレスバーに対応

### レスポンシブUI実装例
- ユーザー一覧: PC（テーブル）/ モバイル（カード）
- 練習履歴: PC（テーブル）/ モバイル（カード）
- ダッシュボード: PC（4カラムグリッド）/ モバイル（1カラムスタック）

---

## 7. ダークモード（✅ Day 11完了）

### 概要
- Tailwind CSS v4 のクラスベースダークモード
- Light / Dark / System の3つのテーマ選択
- LocalStorageで設定を永続化

### 実装
- テーマ切り替えボタン（サイドバー）
- Stimulus コントローラー（theme_controller.js）で制御
- `dark:` クラスで全ページのダークモード対応
- システム設定との連動（`prefers-color-scheme` メディアクエリ）

### デザイン
- Light: グレー・白ベース
- Dark: ダークグレー・黒ベース
- アクセントカラー: 青・緑・赤（ダークモードでも視認性を保つ）

---

## 8. URL構造（✅ Day 17完了）

### 設計方針
- 個人ページは `/my` 名前空間に統一
- ユーザープロフィールは `/@username` 形式で公開
- 管理者ページは `/admin` 名前空間

### URL一覧

**公開ページ（認証不要）:**
- `/` - トップページ（レッスン一覧）
- `/practices/:id` - 練習ページ（数値IDベース）
- `/@:username` - ユーザープロフィール
- `/terms` - 利用規約
- `/privacy` - プライバシーポリシー
- `/about` - Aboutページ

**個人ページ（認証必要、`/my`配下）:**
- `/my` - マイページ（設定ダッシュボード）
- `/my/account/edit` - アカウント設定（username編集）
- `/my/keymaps` - キーマップ一覧
- `/my/keymaps/:slug/edit` - キーマップ編集
- `/my/history` - 練習履歴

**管理者ページ（認証+管理者権限必須、`/admin`配下）:**
- `/admin` - 管理者ダッシュボード
- `/admin/users` - ユーザー一覧
- `/admin/users/:id` - ユーザー詳細

**認証:**
- `POST /auth/google` - Google認証
- `DELETE /logout` - ログアウト

---

## 9. ユーザー名機能（✅ Day 17完了）

### 概要
- `/@username` 形式のプロフィールページ
- Gmail互換のバリデーション（英数字、ピリオド、ハイフン、アンダースコア）
- 初回ログイン時にGmailアドレスから自動生成

### バリデーション
- 3-30文字
- 英数字、ピリオド、ハイフン、アンダースコア
- ユニーク制約
- 予約語チェック（admin, api, my など）

### プロフィールページ
- ユーザー基本情報（アバター、名前、ユーザー名）
- 統計情報（総練習回数、平均正答率、総キーマップ数）
- 公開キーマップ一覧（将来実装）

---

## 10. SEO/SNS対応（✅ Day 15完了）

### OGP設定
- `og:title`, `og:description`, `og:image`, `og:url`
- Twitter Card対応（`twitter:card`, `twitter:title`, `twitter:description`, `twitter:image`）
- ページごとにカスタマイズ可能

### meta タグ
- `description`, `keywords`
- `viewport`（レスポンシブ対応）

---

## 11. セキュリティ（✅ Day 15完了）

### 実装済み対策
- **CSRF保護**: Rails標準のCSRF保護
- **Strong Parameters**: 全コントローラで適切に実装
- **環境変数管理**: `credentials.yml.enc`（Google Client ID/Secret）
- **IDトークン検証**: `google-id-token` gem
- **Brakeman**: 0警告達成（Day 16, Day 19）
- **Content Security Policy (CSP)**: `config/initializers/content_security_policy.rb`

### CSP設定
- Googleログインとの競合を解消（nonce無効化、`:unsafe_inline`有効化）
- インラインスタイル（`style=`属性）は使用禁止
- Tailwind CSSのユーティリティクラスは問題なし

---

## 12. 本番環境デプロイ（✅ Day 14完了）

### インフラ
- さくらVPS（Ubuntu 22.04）
- Kamal経由でDockerコンテナデプロイ
- PostgreSQL 14（VPS内で直接稼働）

### ドメイン
- typnix.com（独自ドメイン）
- DNS: Cloudflare経由
- SSL/TLS: Let's Encrypt（Kamalで自動設定、90日ごとに自動更新）
- エンドツーエンド暗号化（ブラウザ → Cloudflare → VPS）

### デプロイフロー
1. `kamal setup`（初回のみ）
2. `kamal deploy`（コード変更時）
3. `kamal app exec bin/rails db:migrate`（マイグレーション実行時）

---

## まとめ

**実装完了した主要機能:**
1. ✅ ユーザー認証（Google Identity Services）
2. ✅ キーマップ管理（複数管理、KeymapSet、slug対応）
3. ✅ タイピング練習（レッスンシステム、指ガイド、レイヤー自動判定）
4. ✅ 練習履歴・統計（自動クリーンアップ、レスポンシブUI）
5. ✅ 管理者ダッシュボード（ユーザー統計、人気レッスンランキング）
6. ✅ レスポンシブ対応（モバイル・PC両対応）
7. ✅ ダークモード（Light/Dark/System）
8. ✅ URL構造整理（RESTful設計）
9. ✅ ユーザー名機能（`/@username`）
10. ✅ SEO/SNS対応（OGP、Twitter Card）
11. ✅ セキュリティ強化（Brakeman 0警告）
12. ✅ 本番環境デプロイ（https://typnix.com）

**次のステップ:**
- Googleツール導入（GTM + GA4）
- トップページ改修（練習増加 + タブ化）
- キーマップ公開機能（Phase 3、任意）
