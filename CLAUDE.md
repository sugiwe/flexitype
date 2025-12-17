# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# タイピング練習アプリ 開発仕様書

## 📛 サービス名

- **サービス名**: Typnix（タイプニックス）
- **開発コードネーム**: Flexitype（リポジトリ名などで使用）
- アプリ内の表示はすべて「Typnix」を使用

---

## 📋 開発ルール

### Git ブランチ運用

- **必ずブランチを切って作業する**（main ブランチへの直接コミット禁止）
- ブランチ命名規則:
  - 機能追加: `feature/機能名` (例: `feature/google-authentication-setup`)
  - バグ修正: `bugfix/バグ内容` (例: `bugfix/login-button-display`)
  - リファクタリング: `refactor/対象` (例: `refactor/sessions-controller`)
- 作業完了後は、main ブランチにマージしてからブランチを削除
- コミットメッセージは日本語で、変更内容を明確に記述

### コミット運用

- 意味のある単位でコミットを分ける
- コミットメッセージの最後に Claude Code の署名を含める
- 例: 「Google 認証機能の実装を完了」
- **リモートプッシュ前に以下のチェックを実行する:**
  - `bundle exec rubocop`: コード品質チェック
  - `bundle exec brakeman --no-pager`: セキュリティ脆弱性チェック

### 日報管理と CLAUDE.md の連動

#### 日報作成

- 毎日の作業終了時に `docs/daily_reports/YYYY-MM-DD.md` を作成
- テンプレート: `docs/daily_reports/template.md`

#### CLAUDE.md の更新

- **日報作成時は必ず CLAUDE.md も更新する**
- 単なる加筆ではなく、全体の構造を保ちながら更新する
- 更新時のチェックポイント:
  - 進捗状況セクション（「現在の進捗状況」）を最新化
  - 実装完了した機能は「実装済み」を明記
  - 古い情報や重複した記述を整理・削除
  - セクション構成が煩雑になっていないか確認
  - 見出しレベルの一貫性を保つ

#### 日報における情報管理ポリシー

日報は公開される前提で作成する。以下の情報は**絶対に記載しない**:

**秘匿情報（絶対に記載禁止）**:

- パスワード、API キー、シークレットキー
- データベース接続文字列
- 本番環境の設定情報

**個人・サービス識別情報（可能な限り記載しない）**:

- メールアドレス
- Google Client ID、その他のサービス ID
- ユーザー名（GitHub 以外）
- IP アドレス、ドメイン名（開発中のもの）

「知られても致命的ではないが、不必要に公開する必要もない」情報は、抽象化または省略して記載する。
例: 「Google Cloud Console でクライアント ID を作成」（ID の値は記載しない）

### View ファーストな開発

このプロジェクトでは、**View ファーストな開発アプローチ**を採用する。

#### 基本方針

- まず、ある程度のレイアウトを含むビューファイルを先に作成する
- ブラウザで完成版に近い形のページを見ながら開発を進める
- 完成イメージを明確にすることで、必要なデータ構造やロジックを自然に導き出す
- モデルやコントローラは、ビューで必要になったタイミングで実装する

#### メリット

- **モチベーション向上**: ブラウザで視覚的に確認できるため、開発が楽しい
- **完成イメージの明確化**: 必要な機能やデータ構造が見えやすくなる
- **デザイン先行**: Tailwind CSS を使うことで、デザインをコードで直接書ける
- **手戻り削減**: 仕様が明確な場合、後でモデルを追加しても大きな変更が少ない

#### 実装手順

1. ルーティングとコントローラのアクションを最小限で用意
2. ビューファイルにレイアウトとダミーデータを使った完成形を作成
3. ブラウザで表示を確認しながらデザインを調整
4. 必要に応じてモデルやロジックを追加し、ダミーデータを実データに置き換える

#### 注意点

- ダミーデータはビュー内にハードコードするが、後でモデルから取得するように置き換える
- 仕様が不明確な場合は、先にデータ構造を検討する従来のアプローチも併用する

---

## 🎯 プロジェクト概要

### 目的

- Cornix などの分割型・カラムスタッガード配列キーボードのタイピング練習を支援する
- 初期段階では開発者所有の Cornix に特化
- 開発者の Ruby/Rails スキル向上を裏テーマとする
- 25 日間で独自ドメインへのデプロイまで完了させる
- 開発進捗を毎日公開日記形式で記録

### ターゲットユーザー

- 分割型キーボード初心者〜中級者
- 自分専用のキーマップで練習したい人
- レイヤー機能に慣れたい人

---

## 🏗 技術構成

### バックエンド

- Ruby: 3.4.4
- Rails: 8.1.1
- データベース: PostgreSQL
- 認証: Google Identity Services + google-id-token gem (Devise/OmniAuth は使わない)

### フロントエンド

- 基本: Slim テンプレートエンジン
- スタイリング: Tailwind CSS v4 (レスポンシブ対応、ダークモード対応)
- インタラクション: Hotwire (Turbo + Stimulus)
- レスポンシブ: モバイル・PC 両対応（ブレークポイント: 768px）
  - モバイル: ハンバーガーメニュー方式
  - PC: 左固定サイドバー（300px）
- SEO/SNS: OGP 設定、Twitter Card 対応

### インフラ

- デプロイ: Kamal
- サーバー: さくら VPS (PostgreSQL も VPS 内で稼働)
- ドメイン: typnix.com (独自ドメイン取得済み、SSL/TLS 対応)

### データ管理

- キーマップ: DB に保存 (ユーザーごと)
- 練習履歴: DB に保存（実装済み）
- 単語リスト: YAML ファイル管理 (`config/typing_words.yml`、`config/lessons/`)
- UI 設定: LocalStorage (テーマ選択、デスクトップバナー表示状態など)

---

## 💡 機能仕様

### 1. ユーザー認証（実装済み）

- Google ログインのみ
- Google Identity Services + `google-id-token` gem
- セッション管理でログイン状態を保持
- メール許可リスト制（環境変数 `ALLOWED_EMAILS` で管理）

**User モデル:**

```ruby
# カラム
- google_uid (string, unique, not null)
- email (string, unique, not null, max: 254)
- name (string, not null, max: 30)
- icon_url (string, max: 4096)
- history_limit (integer, default: 50, not null)

# アソシエーション
- has_many :keymaps, dependent: :destroy
- has_many :typing_sessions, dependent: :destroy

# クラスメソッド
- from_google(payload): Google認証からユーザーを作成/取得
- email_allowed?(email): メール許可リストチェック

# インスタンスメソッド
- cleanup_old_typing_sessions: 古い履歴を削除
```

**認証フロー:**

1. フロントエンドで Google Identity Services を使用して ID トークンを取得
2. ID トークンを Rails サーバーに送信（POST `/auth/google`）
3. サーバー側で ID トークンを検証
4. メール許可リストをチェック
5. ユーザーを作成またはログイン処理

---

### 2. キーマップ登録・管理（実装済み）

#### デフォルトキーマップとカスタマイズ

- **ログアウト状態でもタイピング練習可能**: デフォルトキーマップで動作
- **キーマップ未設定ユーザーもデフォルトで使える**: 初期状態でもすぐに練習開始できる
- **ログイン後にカスタマイズ可能**: 自分専用のキーマップを登録・保存できる
- デフォルトキーマップ: QWERTY 配列ベースの標準的なキーマップをアプリ側に持つ
- キーマップ読み込み優先順位:
  1. ログイン中 & ユーザーのキーマップ登録済み → ユーザーのカスタムキーマップ
  2. それ以外 → デフォルトキーマップ

#### 物理配列

- Cornix 固定 (6 列 ×3-4 行、左右分割)
- 将来的に他のキーボードに対応する可能性も考慮した設計

#### レイヤー

- 0〜5 の 6 レイヤーに対応
- 各レイヤーごとに異なるキーマップを登録可能

#### 登録 UI

**2 段階選択方式:**

1. 上側: 物理キーボード配列（登録先を選択）
2. 下側: 入力候補ボタン（登録元を選択）

**入力候補の整理:**

- 文字・数字タブ: アルファベット（A/a）、数字・記号ペア（!/1）
- 記号・特殊キータブ: 記号ペア（\_/-）、特殊キー（Space, Enter など）、矢印キー
- 2 段表示で Shift ペアを表現

**操作フロー:**

1. 上のキーボードからキーをクリック → 緑枠でハイライト
2. 下の候補から文字をクリック → 割り当て完了
3. レイヤーごとに切り替えて設定
4. 保存ボタンで DB に保存（ユーザーに紐づく）

**Keymap モデル:**

```ruby
# カラム
- user_id (references users, not null)
- layer (integer, 0-5, not null)
- key_position (string, 例: "L0-R0", not null)
- character (string, max: 20, not null)

# インデックス
- [user_id, layer, key_position], unique: true

# クラスメソッド
- for_user_layer(user_id, layer): 特定レイヤーのキーマップをハッシュで取得
- bulk_upsert(user_id, layer, keymap_hash): キーマップの一括更新
```

---

### 3. タイピング練習（実装済み）

#### レッスンシステム

- **10 カテゴリ、20+レッスン** を用意
- カテゴリ: 単語練習、文章練習、記号練習、プログラミング、日本語入力など
- YAML ファイルで管理 (`config/lessons/`)
- LessonLoader サービスクラスでレッスン情報と練習項目を取得

#### 練習フロー

1. 画面上に 1 単語ずつ表示
2. キー入力ごとに正誤を判定
3. BackSpace で修正可能
4. 正しい入力が完了したら次の単語へ
5. 1 セッション = 20 単語（レッスンにより異なる）
6. セッション完了画面で統計表示（正答率、所要時間、ミス数）

#### 判定ロジック

- 入力文字と正解文字を 1 文字ずつ比較
- 間違えた文字は入力をロック（BackSpace で修正）
- 正しい入力後、次の文字へフォーカス移動

---

### 4. キーボード表示・ガイド機能（実装済み）

#### 描画方法

- CSS Grid + margin 調整でカラムスタッガードを再現
- 将来的に SVG 化も検討

#### 左右分割表示

- 視覚的に左右のキーボードが分かれている表示

#### ハイライト機能

- 次に打つべきキーをリアルタイムでハイライト
- レイヤー切り替えが必要な場合:
  - レイヤーボタン (例: 左親指) + 目的の文字キーの 2 箇所を同時にハイライト
  - 例: "1" を打つ場合 → レイヤー 1 ボタン + レイヤー 1 の"1"の位置

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
  - キーボード下部に左右それぞれ 5 本指のガイドを表示
  - 各指に「小・薬・中・人・親」のラベル
  - 次に使う指のガイドも濃い色に変化

#### レイヤー自動判定

- アプリが次に打つ文字を解析
- ユーザーのキーマップから「どのレイヤーに配置されているか」を自動判定
- 該当レイヤーのキーマップ表示に自動切り替え
- Layer 0 を最優先として検索し、全 6 レイヤーから文字を検索
- レイヤーボタン + 目的の文字キーの 2 箇所を同時にハイライト

#### 2 段表示機能

- キーに 2 段表示（通常時|Shift 時）を表示
- デリミタ: `|`（例: `Q|q`, `!|1`, `?|/`）
- Ruby 版（ApplicationHelper）と JavaScript 版（typing_controller.js）で統一実装
- 特殊キー（Spc, BS, Ent, Lyr1 など）は 1 段表示

---

### 5. 練習履歴・統計（実装済み）

#### 概要

- ログインユーザー向け機能
- 無料ユーザーは 50 件の履歴を保持（自動クリーンアップ）
- 将来の課金ユーザー向けに拡張可能な設計

#### データベース設計

**TypingSession モデル:**

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

# インデックス
- [user_id, completed_at], order: { completed_at: :desc }
- [user_id, created_at], order: { created_at: :desc }

# スコープ
- recent: order(completed_at: :desc)

# コールバック
- after_create :cleanup_old_sessions
```

#### 自動クリーンアップ

- TypingSession 作成後、after_create コールバックで実行
- history_limit を超えた古い履歴を自動削除
- パフォーマンスを考慮したインデックス設計

#### 履歴一覧ページ（/history）

- **レスポンシブ UI**
  - PC: テーブル形式（日時、レッスン、単語数、正答率、所要時間、ミス数）
  - モバイル: カード形式（同じ情報をコンパクトに表示）
- **ミニ統計**
  - 総練習回数（青色アイコン）
  - 平均正答率（緑色アイコン）
- **正答率の色分け**
  - 90%以上: 緑色
  - 70%以上: 黄色
  - それ以下: 赤色
- **ページネーション**: Kaminari gem、1 ページ 20 件
- **空状態 UI**: 履歴なし時の誘導メッセージ

#### 自動保存機能

- タイピング練習終了時に自動的に履歴を保存
- typing_controller.js で JSON API を呼び出し（POST `/history`）
- ログインユーザーのみ保存（loggedInValue で判定）
- CSRF 対策、エラーハンドリング

#### 将来の拡張

- 統計グラフ（正答率の推移など）
- 詳細な統計ページ（/history/stats）
- WPM（Words Per Minute）の記録

---

## 📦 データモデル

### User

```ruby
# カラム
- id (primary key)
- google_uid (string, unique, indexed)
- email (string, max: 254, unique)
- name (string, max: 30)
- icon_url (string, max: 4096)
- history_limit (integer, default: 50)
- created_at, updated_at

# アソシエーション
- has_many :keymaps, dependent: :destroy
- has_many :typing_sessions, dependent: :destroy

# メソッド
- self.from_google(payload): Google認証からユーザーを作成/取得
- self.email_allowed?(email): メール許可リストチェック
- cleanup_old_typing_sessions: 古い履歴を削除
```

### Keymap

```ruby
# カラム
- id (primary key)
- user_id (references User)
- layer (integer, 0-5)
- key_position (string, 例: "L0-R0")
- character (string, max: 20)
- created_at, updated_at

# インデックス
- [user_id, layer, key_position], unique: true

# スコープ・メソッド
- for_user_layer(user_id, layer): 特定レイヤーのキーマップをハッシュで取得
- bulk_upsert(user_id, layer, keymap_hash): キーマップの一括更新
```

### TypingSession

```ruby
# カラム
- id (primary key)
- user_id (references User, not null)
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

---

## 📅 開発スケジュール (25 日間)

### Phase 1: 基盤構築 (Day 1-3) ✅

- Day 1: 構想・仕様策定
- Day 2: Rails 新規作成、Git 初期化、Tailwind CSS・Slim 導入、Google 認証基本実装
- Day 3: Google Cloud Console 設定完了、認証動作確認

### Phase 2: コア機能実装 (Day 4-8) ✅

- Day 4-5: タイピング練習画面とタイピング判定ロジック実装
  - キーボード描画 (CSS Grid で Cornix の分割型配列を再現)
  - 単語表示エリアと入力フォームのレイアウト
  - Stimulus コントローラで入力判定、BackSpace 対応
  - 単語データの YAML ファイル作成と読み込み
  - 指ガイド機能の実装（指ごとの色分け、ハイライト）
  - ミスタイプ時の入力ロック機能
- Day 6-7: キーマップ登録・保存機能
  - キーマップ登録画面の View 作成（2 段階選択方式）
  - Keymap モデル実装と DB 保存
  - デフォルトキーマップシステム（YAML）
  - タイピング練習画面への動的反映
- Day 8: 統合テスト・調整
  - レイヤー自動切り替え機能（全レイヤー自動判定、2 箇所同時ハイライト）
  - 2 段表示機能（Q|q 形式、デリミタ統一）
  - UI/UX 改善（自動フォーカス、ハイライト抑制）

### Phase 3: UX 向上・UI 改善 (Day 9-12) ✅

- Day 9: セッション完了画面とレッスン選択システム
  - セッション完了画面（統計表示：正答率、所要時間、ミス数）
  - レッスン選択システム（10 カテゴリ・20+レッスン）
  - LessonLoader サービスクラスの実装
- Day 10: レイアウトの全面的リデザイン
  - 左カラムサイドバー方式への変更
  - ナビゲーション、ユーザー情報、広告スペース
  - サービス名を「Typnix」に統一
- Day 11: ダークモード機能の実装
  - Tailwind CSS v4 でのクラスベースダークモード
  - Light/Dark/System の 3 つのテーマ選択
  - LocalStorage で設定を永続化
- Day 12: ベータ版リリース準備とリファクタリング
  - ベータ版制限 UI 実装
  - 利用規約・プライバシーポリシーページ
  - ヘルプメニュー・ユーザーメニュー実装
  - レイアウトファイルリファクタリング（application.html.slim を 205 行 →45 行に削減）

### Phase 4: デプロイ (Day 13-14) ✅

- Day 13: VPS 初回デプロイ
  - さくら VPS（Ubuntu 22.04）の初期設定
  - Docker のインストールと設定
  - PostgreSQL 14 のインストール
  - Kamal デプロイ設定
  - http://153.120.65.157 で外部アクセス可能に
- Day 14: 独自ドメイン・Full SSL 設定
  - DNS A レコード設定（typnix.com → VPS IP）
  - SSL/TLS 暗号化モードを「Full」に設定
  - Let's Encrypt で自動 SSL 証明書取得
  - https://typnix.com で公開開始

### Phase 5: セキュリティ・レスポンシブ対応 (Day 15) ✅

- Day 15: セキュリティ強化とレスポンシブ対応の完成
  - 包括的なセキュリティチェックリストの作成（50+項目）
  - KeymapsController に Strong Parameters 実装
  - Brakeman: 0 警告達成
  - モバイル・PC 両対応のレスポンシブ UI
  - ハンバーガーメニュー方式（モバイル）
  - モバイルブラウザのアドレスバー対応（100dvh 使用）
  - OGP 設定（SNS シェア対応）

### Phase 6: 履歴機能 (Day 16) ✅

- Day 16: タイピング練習履歴機能の実装
  - TypingSession モデル作成
  - 自動クリーンアップ機能（50 件制限）
  - 履歴一覧ページ（レスポンシブ対応）
  - ミニ統計表示（総回数、平均正答率）
  - 本番環境デプロイ成功
  - KeymapsController セキュリティ改善（Brakeman 警告 0 件達成）

### Phase 7: ブラッシュアップ (Day 17-25)

- バグ修正
- UI/UX 改善
- パフォーマンス最適化
- エラーページ（404/500）の整備
- ログ・モニタリング体制の確立
- 統計機能の拡張（任意）

---

## 🎨 UI/UX 設計方針

### レイアウト

**左カラムサイドバー方式（実装済み）**

- 左サイドバー: 300px 固定幅
  - ロゴエリア
  - ナビゲーションメニュー
  - 広告スペース（300x250px）
  - ユーザー情報・認証エリア
- 右メインコンテンツ: 可変幅
  - ページごとのコンテンツ
  - レスポンシブ対応（デスクトップ優先）

### カラースキーム

- シンプルで視認性の高い配色
- ハイライト色: アクセントカラー (例: 青・緑系)
- エラー表示: 赤系
- ダークモード対応（全ページ）

### アニメーション

- キー押下時の視覚フィードバック (CSS transition)
- レイヤー切り替え時のスムーズな表示変更
- テーマ切り替えアニメーション

---

## 🔒 セキュリティ・認証

- CSRF 対策: Rails 標準の CSRF 保護
- 環境変数管理: `credentials.yml.enc`（Google Client ID/Secret）
- メール許可リスト: 環境変数 `ALLOWED_EMAILS`（カンマ区切り）
- ID トークン検証: `google-id-token` gem
- Strong Parameters: 全コントローラで適切に実装
- セキュリティチェック: Brakeman、bundler-audit で定期的に検査

---

## 🚀 デプロイ構成

### さくら VPS

- Rails アプリ (Kamal 経由でコンテナデプロイ)
- PostgreSQL (VPS 内で直接稼働)

### 独自ドメイン

- ドメイン: typnix.com
- DNS: Cloudflare 経由
- SSL/TLS: Let's Encrypt (Kamal で自動設定、90 日ごとに自動更新)
- エンドツーエンド暗号化（ブラウザ →Cloudflare→VPS）

---

## 🗺️ URL構造設計（✅ Day 17 で整理完了）

### 設計方針

**個人ページは `/my` 名前空間に統一**
- 認証が必要なユーザー個人のページは `/my/*` にまとめる
- 将来的な機能拡張（複数キーマップ、カスタムレッスン、アカウント設定など）を見据えた設計
- ユーザープロフィールは `/@username` 形式で公開

### URL一覧

#### 公開ページ（認証不要）
- `/` - トップページ（レッスン一覧）
- `/practices/:id` - 練習ページ（例: `/practices/1`, `/practices/7`）
- `/@:username` - ユーザープロフィール（例: `/@john`, `/@alice`）
- `/terms` - 利用規約
- `/privacy` - プライバシーポリシー

#### 個人ページ（認証必要、`/my` 名前空間）
- `/my` - マイページ（設定ダッシュボード）
- `/my/account/edit` - アカウント設定（username編集）
- `/my/keymaps/1/edit` - キーマップ編集（現在はID=1固定、将来的に複数対応）
- `/my/history` - 練習履歴

#### 認証
- POST `/auth/google` - Google認証
- DELETE `/logout` - ログアウト

### 将来的な拡張
- `/my/keymaps` - キーマップ一覧（複数対応）
- `/my/lessons` - カスタムレッスン管理

---

## 📝 今後の予定タスク

### 優先度: 高（Phase 7 で実装予定）

#### 1. アクセス制御の実装（Day 18 予定）
- ログイン必須の練習ページへの非ログインユーザーのアクセスを制限
- リダイレクト処理とフラッシュメッセージの実装
- LessonLoader側で `requires_login` フラグを活用

#### 3. Googleツール系の導入（Day 19 予定）
- **Google Tag Manager（GTM）での一括管理**
  - アナリティクス、アドセンス、将来的な他のタグも一元管理
  - コード変更なしでタグを追加・変更できる
- **GA4（Googleアナリティクス）の設定**
  - ユーザー行動データの蓄積開始
  - ページ別アクセス解析
- **プライバシーポリシーの更新**
  - Cookie使用、データ収集について明記
- **Googleアドセンスの導入**（審査が必要、後回しでもOK）

#### 3. トップページのデザイン改修（Day 20 予定）
- 練習を増やす（現在16レッスン → 30+レッスン）
- タブ分けによるカテゴリ整理
  - 基本練習（誰でも）
  - 単語練習（誰でも）
  - プログラミング（ログイン必要）
  - 文章練習（ログイン必要）
  - カスタム（ログイン必要）

### 優先度: 中（余裕があれば実装）

#### 4. キーマップ設定の充実
- ファンクションキー（F1-F12）の追加
- 修飾キー組み合わせ（Ctrl+C など）
- マウスキー
- マクロ

#### 5. エラーページの整備
- 404ページのカスタマイズ
- 500ページのカスタマイズ
- ユーザーフレンドリーなメッセージ

### 優先度: 低（将来的に検討）

#### 6. 練習後のシェア機能
- **クライアントサイド生成を推奨**（画像ストレージ不要）
  - HTML Canvas APIで画像を生成
  - 背景画像（SVGまたはPNG）+ テキスト描画
  - `canvas.toDataURL()`でBlobを生成してダウンロード
  - Twitter/X シェアはテキスト + URLのみ

#### 7. その他の拡張案（MVP 後）
- 他のキーボード配列対応 (Corne, Lily58 など)
- QMK/VIA の JSON ファイルインポート機能
- タイマー・WPM 表示
- ランキング機能
- キーボード描画の SVG 化
- 言語切り替え（多言語対応）
- カスタムテーマ（GitHub 風など）の追加
- 統計グラフ（正答率の推移など）
- 詳細な統計ページ（/history/stats）

---

## 🎯 現在の進捗状況

**Day 17 完了（2025-12-17 時点）**

### 完了した機能

- ✅ ユーザー認証（Google ログイン）
- ✅ キーマップ登録・管理
- ✅ タイピング練習（レッスンシステム、指ガイド、レイヤー自動判定）
- ✅ 練習履歴・統計（自動クリーンアップ、レスポンシブ UI）
- ✅ ダークモード
- ✅ レスポンシブ対応（モバイル・PC 両対応）
- ✅ 本番環境デプロイ（https://typnix.com）
- ✅ セキュリティ強化（Brakeman 警告 0 件）
- ✅ **練習ページの個別URL化（数値IDベース）** ← Day 17 で完了

- ✅ **URL構造の全面的な整理** ← Day 17 で完了
- ✅ **ユーザー名（username）機能の実装** ← Day 17 で完了

### 最近の更新（Day 17）

**1. 練習ページの個別URL化（数値IDベース）**
- URL形式: `/practice?category=xxx&lesson=xxx` → `/practices/:id`
- 全16レッスンに数値ID（1-16）を割り当て
- Rails標準の`resources`ルーティングを使用
- DB化を見据えた拡張性の高い設計

**2. URL構造の全面的な整理**
- `/my`名前空間による個人ページの整理
  - `/history` → `/my/history`
  - `/keymaps/current/edit` → `/my/keymaps/1/edit`
  - 新規: `/my`（マイページ）
  - 新規: `/my/account/edit`（アカウント設定）
- `My::ApplicationController`でDRY原則に従い認証ロジックを集約
- RESTful設計（`resource :account`, `resources :keymaps`）

**3. ユーザー名（username）機能の実装**
- `/@username`形式のプロフィールページ
- Gmail互換のバリデーション（ドット、ハイフン、アンダースコア対応）
- 初回ログイン時にGmailアドレスから自動生成
- アカウント設定画面でusername編集可能
- プロフィールURLプレビュー機能

### 次のステップ（Phase 7: ブラッシュアップ）

**Week 1: 基盤整備**
- Day 18: アクセス制御の実装（ログイン必須レッスンの制限）
- Day 19: Googleツール導入（GTM + GA4 + プライバシーポリシー更新）

**Week 2: 機能拡張**
- Day 20: トップページ改修（練習増加 + タブ化）
- Day 21-22: その他の改善（エラーページ、キーマップ設定など）
- Day 23-24: バグ修正、パフォーマンス最適化
- Day 25: 最終チェック、ドキュメント整備

### 技術的マイルストーン

- 25 日間で独自ドメインへのデプロイ完了という目標に対し、Day 14 で達成
- 主要機能（練習、キーマップ設定、履歴）がすべて完成し、本番環境で稼働中
- セキュリティ、レスポンシブ対応、ダークモードなど、プロダクション品質のアプリケーションとして完成度が高い状態
- Day 17: 数値IDベースのURL設計により、将来的なDB化の基盤が整った

---

## 🗺 将来的な拡張計画

### キーマップ機能の拡張設計（Phase X）

**現状の課題:**
- ユーザーごとに1つのキーマップのみ（`/my/keymaps/1`固定）
- 複数のキーマップを管理できない
- キーマップの公開・共有機能がない

**将来の目標:**
- 複数キーマップ管理（無課金2つ、課金5つまで）
- キーマップの公開・共有機能
- 他ユーザーのキーマップをフォーク（コピー）

#### データベース設計（RESTful分割案）

**KeymapSet モデル（キーマップセット）**
```ruby
class KeymapSet < ApplicationRecord
  belongs_to :user
  has_many :keymap_layers, dependent: :destroy

  # カラム
  - name: string (キーマップ名、例: "デフォルト", "プログラミング用")
  - description: text (キーマップの説明、nullable)
  - is_public: boolean (公開設定、デフォルト: false)
  - share_token: string (公開用トークン、unique、インデックス)
  - forked_from_id: integer (フォーク元のKeymap SetID、nullable)
  - created_at, updated_at

  # アソシエーション
  - belongs_to :user
  - has_many :keymap_layers, dependent: :destroy

  # バリデーション
  - validates :name, presence: true, length: { maximum: 50 }
  - validates :description, length: { maximum: 500 }
  - validate :check_user_keymap_limit

  # スコープ
  - scope :public_keymaps, -> { where(is_public: true) }

  # メソッド
  - generate_share_token: 公開時にトークンを生成
  - fork_to(user): 別のユーザーにフォーク
end
```

**KeymapLayer モデル（各レイヤーのキー配置）**
```ruby
class KeymapLayer < ApplicationRecord
  belongs_to :keymap_set

  # カラム
  - keymap_set_id: references KeymapSet
  - layer: integer (0-5)
  - key_position: string (例: "L0-R0")
  - character: string (max: 20)
  - created_at, updated_at

  # インデックス
  - [keymap_set_id, layer, key_position], unique: true

  # バリデーション
  - validates :layer, presence: true, inclusion: { in: 0..5 }
  - validates :key_position, presence: true
  - validates :character, presence: true, length: { maximum: 20 }
end
```

#### URL設計

**個人のキーマップ管理（認証必須、`/my`配下）**
```ruby
GET    /my/keymaps          # キーマップ一覧
GET    /my/keymaps/new      # 新規作成フォーム
POST   /my/keymaps          # 新規作成
GET    /my/keymaps/:id      # 詳細表示
GET    /my/keymaps/:id/edit # 編集フォーム
PATCH  /my/keymaps/:id      # 更新
DELETE /my/keymaps/:id      # 削除
```

**公開キーマップ（認証不要、`/@username`配下）**
```ruby
GET    /@:username/keymaps          # ユーザーの公開キーマップ一覧
GET    /@:username/keymaps/:id      # 特定の公開キーマップ詳細
POST   /@:username/keymaps/:id/fork # フォーク（要認証）
```

#### 段階的な実装アプローチ

**Phase 1: 現状維持（緊急修正のみ）**
- 2025-12-17 完了
- JavaScript URL修正（`/my/keymaps/1`に対応）
- デフォルトに戻す機能（DELETE リクエストで全削除）

**Phase 2: 複数キーマップ対応**
- KeymapSet + KeymapLayer モデルの作成
- マイグレーション：既存Keymapデータを移行
- `/my/keymaps` 一覧ページの実装
- 新規作成・削除機能の実装
- 無課金ユーザーは2つまで制限（`check_user_keymap_limit`バリデーション）
- 将来の課金ユーザーは5つまで

**Phase 3: 公開・共有機能**
- `is_public`, `share_token` カラムの活用
- 公開設定UI（トグルボタン）
- `/@username/keymaps`での公開キーマップ一覧表示
- フォーク機能の実装
- フォーク元のリンク表示

#### 機能要件

**キーマップ一覧（`/my/keymaps`）**
- キーマップの一覧をカード形式で表示
- 各カード: 名前、説明、作成日時、公開状態
- 新規作成ボタン（制限に達している場合は非表示）
- 編集・削除ボタン

**キーマップ詳細・編集（`/my/keymaps/:id/edit`）**
- 名前・説明の編集
- 6レイヤーのキー配置編集（現在の実装と同じUI）
- 公開設定トグル
- 保存・キャンセルボタン

**公開キーマップ一覧（`/@username/keymaps`）**
- ユーザーの公開キーマップのみ表示
- 各カード: 名前、説明、作成日時
- フォークボタン（要ログイン）

**公開キーマップ詳細（`/@username/keymaps/:id`）**
- キーマップの詳細表示（読み取り専用）
- 6レイヤーのキー配置を視覚的に表示
- フォークボタン（自分のキーマップとしてコピー）
- フォーク元の表示（フォークされたキーマップの場合）

#### 設計の利点

**RESTful設計:**
- KeymapSetとKeymap Layerの分離により、Railsの標準的なリソース設計に従う
- ルーティングがシンプルで拡張しやすい
- コントローラのアクションも標準的なCRUD操作

**拡張性:**
- 課金機能追加時に、キーマップ数制限を柔軟に変更可能
- 将来的にキーマップのテンプレート機能なども追加しやすい
- フォーク機能により、コミュニティ的な要素を強化

**ユーザビリティ:**
- 用途別にキーマップを使い分けられる（プログラミング、ゲーム、日常など）
- 他のユーザーの設定を参考にできる
- `/@username/keymaps`により、プロフィールと統一感のあるURL設計

#### 実装時の注意点

**マイグレーション:**
- 既存のKeymapデータをKeymapSetとKeymap Layerに移行
- ユーザーごとに「デフォルト」という名前のKeymap Setを作成
- データの整合性を保つため、トランザクション内で処理

**制限の実装:**
- `check_user_keymap_limit`バリデーションで、ユーザーのキーマップ数をチェック
- 無課金ユーザー: 2つまで
- 課金ユーザー（将来）: 5つまで
- 制限に達している場合は、新規作成ボタンを非表示にし、エラーメッセージを表示

**公開設定:**
- デフォルトは非公開（`is_public: false`）
- 公開時に`share_token`を自動生成（SecureRandom.urlsafe_base64(16)など）
- 公開URLは`/@username/keymaps/:id`形式

**フォーク機能:**
- フォーク時に、元のKeymap SetのKeymap Layerを全てコピー
- `forked_from_id`に元のKeymap Set IDを保存
- フォーク元のリンクを表示して、クレジットを明示

---
