# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# タイピング練習アプリ 開発仕様書

## 📋 開発ルール

### Git ブランチ運用

- **必ずブランチを切って作業する**（mainブランチへの直接コミット禁止）
- ブランチ命名規則:
  - 機能追加: `feature/機能名` (例: `feature/google-authentication-setup`)
  - バグ修正: `bugfix/バグ内容` (例: `bugfix/login-button-display`)
  - リファクタリング: `refactor/対象` (例: `refactor/sessions-controller`)
- 作業完了後は、mainブランチにマージしてからブランチを削除
- コミットメッセージは日本語で、変更内容を明確に記述

### コミット運用

- 意味のある単位でコミットを分ける
- コミットメッセージの最後に Claude Code の署名を含める
- 例: 「Google認証機能の実装を完了」

### 日報管理

- 毎日の作業終了時に `docs/daily_reports/YYYY-MM-DD.md` を作成
- テンプレート: `docs/daily_reports/template.md`

#### 日報における情報管理ポリシー

日報は公開される前提で作成する。以下の情報は**絶対に記載しない**:

**秘匿情報（絶対に記載禁止）**:
- パスワード、APIキー、シークレットキー
- データベース接続文字列
- 本番環境の設定情報

**個人・サービス識別情報（可能な限り記載しない）**:
- メールアドレス
- Google Client ID、その他のサービスID
- ユーザー名（GitHub以外）
- IPアドレス、ドメイン名（開発中のもの）

「知られても致命的ではないが、不必要に公開する必要もない」情報は、抽象化または省略して記載する。
例: 「Google Cloud ConsoleでクライアントIDを作成」（IDの値は記載しない）

### Viewファーストな開発

このプロジェクトでは、**Viewファーストな開発アプローチ**を採用する。

#### 基本方針

- まず、ある程度のレイアウトを含むビューファイルを先に作成する
- ブラウザで完成版に近い形のページを見ながら開発を進める
- 完成イメージを明確にすることで、必要なデータ構造やロジックを自然に導き出す
- モデルやコントローラは、ビューで必要になったタイミングで実装する

#### メリット

- **モチベーション向上**: ブラウザで視覚的に確認できるため、開発が楽しい
- **完成イメージの明確化**: 必要な機能やデータ構造が見えやすくなる
- **デザイン先行**: Tailwind CSSを使うことで、デザインをコードで直接書ける
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
- スタイリング: Tailwind CSS (固定レイアウト、横 1200px 想定)
- インタラクション: Hotwire (Turbo + Stimulus)
- レスポンシブ: 不要 (デスクトップ専用)

### インフラ

- デプロイ: Kamal
- サーバー: さくら VPS (PostgreSQL も VPS 内で稼働)
- ドメイン: 独自ドメイン取得予定

### データ管理

- キーマップ: DB に保存 (ユーザーごと)
- 練習履歴: DB に保存 (後期実装)
- 単語リスト: YAML ファイル管理 (`config/typing_words.yml`)
- UI 設定: LocalStorage (ヒント表示 ON/OFF など)

---

## 💡 機能仕様

### 1. ユーザー認証

- Google ログインのみ
- Google Identity Services + `google-id-token` gem
- セッション管理でログイン状態を保持
- メール許可リスト制（環境変数 `ALLOWED_EMAILS` で管理）

User モデル:

```ruby
# 必須カラム
- google_uid (string, unique, not null)
- email (string, unique, not null)
- name (string)
```

認証フロー:
1. フロントエンドでGoogle Identity Servicesを使用してIDトークンを取得
2. IDトークンをRailsサーバーに送信（POST `/auth/google`）
3. サーバー側でIDトークンを検証
4. メール許可リストをチェック
5. ユーザーを作成またはログイン処理

---

### 2. キーマップ登録・管理

#### 物理配列

- Cornix 固定 (6 列 ×3-4 行、左右分割)
- 将来的に他のキーボードに対応する可能性も考慮した設計

#### レイヤー

- 0〜5 の 6 レイヤーに対応
- 各レイヤーごとに異なるキーマップを登録可能

#### 登録 UI

- キーボード画面上で各キーをクリック → 割り当てたい文字を入力
- レイヤーごとに切り替えて設定
- 保存は DB (ユーザーに紐づく)

Keymap モデル (例):

ruby

```ruby
# カラム案
- user_id (references)
- layer (integer, 0-5)
- key_position (string, 例: "L0-R0" = 左手0列0行)
- character (string, 割り当てた文字)
```

---

### 3. タイピング練習

#### 単語データ

- YAML ファイルで管理 (`config/typing_words.yml`)

yaml

```yaml
beginner:
  - apple
  - hello
  - world
intermediate:
  - keyboard
  - typing
```

- 初期はハードコード、後で難易度別・カテゴリ別に拡張可能

#### 練習フロー

1. 画面上に 1 単語ずつ表示
2. キー入力ごとに正誤を判定
3. BackSpace で修正可能
4. 正しい入力が完了したら次の単語へ
5. 1 セッション = 20 単語

#### 判定ロジック

- 入力文字と正解文字を 1 文字ずつ比較
- 間違えた文字は赤字などでハイライト
- 正しい入力後、次の文字へフォーカス移動

---

### 4. キーボード表示・ガイド機能

#### 描画方法

- 初期: CSS Grid + margin 調整でカラムスタッガードを再現
- 将来的に SVG 化も検討

#### 左右分割表示

- 視覚的に左右のキーボードが分かれている表示

#### ハイライト機能

- 次に打つべきキーをリアルタイムでハイライト
- レイヤー切り替えが必要な場合:
  - レイヤーボタン (例: 左親指) + 目的の文字キーの 2 箇所を同時にハイライト
  - 例: "1" を打つ場合 → レイヤー 1 ボタン + レイヤー 1 の"1"の位置

#### 指ガイド機能（実装済み）

- **指ごとの色分け:**
  - 小指（左右）: 赤色（`bg-red-100` / `bg-red-300`）
  - 薬指（左右）: 黄色（`bg-yellow-100` / `bg-yellow-300`）
  - 中指（左右）: 青色（`bg-blue-100` / `bg-blue-300`）
  - 人差し指（左右）: 緑色（`bg-green-100` / `bg-green-300`）
  - 親指（左右）: グレー（`bg-gray-100` / `bg-gray-300`）
- **キーの色付け:**
  - 各キーに指ごとの薄い色を常時表示
  - 次に打つべきキーは、その指の色が濃くなる
  - リングエフェクト（`ring-4` `ring-offset-2`）で強調
- **指ガイド表示:**
  - キーボード下部に左右それぞれ5本指のガイドを表示
  - 各指に「小・薬・中・人・親」のラベル
  - 次に使う指のガイドも濃い色に変化
- **実装詳細:**
  - `fingerMapping`: 指とキーの対応関係を定義
  - `fingerColors`: 各指の薄い色（light）と濃い色（dark）を定義
  - `applyFingerColors()`: ページ読み込み時に全キーに色を適用
  - `highlightNextKey()`: 入力に応じて次のキーと指をハイライト

#### レイヤー自動判定（未実装）

- アプリが次に打つ文字を解析
- ユーザーのキーマップから「どのレイヤーに配置されているか」を判定
- 該当レイヤーのキーマップ表示に自動切り替え

#### ヒント表示 ON/OFF（未実装）

- Stimulus でページ遷移なく切り替え
- 設定は LocalStorage に保存 (次回訪問時も反映)

---

### 5. 練習履歴・統計 (後期実装)

- 練習日時、単語数、正答率などを DB 保存
- 履歴一覧ページ
- 統計グラフ (正答率の推移など)

---

## 📅 開発スケジュール (25 日間)

### Phase 1: 基盤構築 (Day 1-3)

- Day 1: 構想・仕様策定
- Day 2: Rails 新規作成、Git 初期化、Tailwind CSS・Slim導入、Google認証基本実装（完了）
- Day 3: Google Cloud Console設定完了、認証動作確認

### Phase 2: コア機能実装 (Day 4-11) ※Viewファーストなアプローチ

- Day 4-5: タイピング練習画面のView作成とタイピング判定ロジック実装 ✅ **完了**
  - キーボード描画 (CSS Grid でCornixの分割型配列を再現)
  - 単語表示エリアと入力フォームのレイアウト
  - Stimulus コントローラで入力判定
  - BackSpace 対応、リアルタイムハイライト
  - 単語データのYAMLファイル作成と読み込み
  - 指ガイド機能の実装（指ごとの色分け、ハイライト）
  - ミスタイプ時の入力ロック機能
- Day 6-7: キーマップ登録・保存機能（調整）
  - キーマップ登録画面のView作成
  - Keymapモデル実装とDB保存
- Day 8: 統合テスト・調整
  - タイピング練習とキーマップ機能の連携確認
  - バグ修正・UI調整

**進捗状況:** Day 7-8の内容を前倒しで実装完了。予定より2-3日早く進行中。

### Phase 3: UX 向上 (Day 12-14)

- ヒント表示 ON/OFF 機能 (Stimulus)
- セッション完了画面
- レイヤー自動判定・2 箇所ハイライト

### Phase 4: 履歴機能 (Day 15-17)

- 練習履歴の DB 保存
- 履歴一覧ページ
- 簡易統計表示

### Phase 5: デプロイ (Day 18-21)

- Kamal セットアップ
- さくら VPS への初回デプロイ
- PostgreSQL セットアップ (VPS 内)
- 独自ドメイン取得・設定

### Phase 6: ブラッシュアップ (Day 22-25)

- バグ修正
- UI/UX 改善
- パフォーマンス最適化
- 統計機能の拡張 (任意)

---

## 📦 データ構造 (案)

### User

ruby

```ruby
- id
- google_uid (string, unique, indexed)
- email (string)
- name (string)
- created_at
- updated_at
```

### Keymap

ruby

```ruby
- id
- user_id (references User)
- layer (integer, 0-5)
- key_position (string, 例: "L0-R0")
- character (string)
- created_at
- updated_at

# インデックス
- index: [user_id, layer, key_position], unique: true
```

### TypingSession (後期実装)

ruby

```ruby
- id
- user_id (references User)
- word_count (integer)
- accuracy (decimal, 正答率)
- completed_at (datetime)
- created_at
- updated_at
```

---

## 🎨 UI/UX 設計方針

### レイアウト

- 固定幅 1200px
- 上部: ヘッダー (ログイン情報、設定リンク)
- 中央: 練習エリア (単語表示、入力フォーム)
- 下部: キーボード表示

### カラースキーム

- シンプルで視認性の高い配色
- ハイライト色: アクセントカラー (例: 青・緑系)
- エラー表示: 赤系

### アニメーション

- キー押下時の視覚フィードバック (CSS transition)
- レイヤー切り替え時のスムーズな表示変更

---

## 🔒 セキュリティ・認証

- CSRF 対策: Rails標準のCSRF保護
- 環境変数管理: `credentials.yml.enc`（Google Client ID/Secret）
- メール許可リスト: 環境変数 `ALLOWED_EMAILS`（カンマ区切り）
- IDトークン検証: `google-id-token` gem

---

## 🚀 デプロイ構成

### さくら VPS

- Rails アプリ (Kamal 経由でコンテナデプロイ)
- PostgreSQL (VPS 内で直接稼働)

### 独自ドメイン

- 取得後、DNS 設定で VPS の IP に向ける
- SSL/TLS: Let's Encrypt (Kamal で自動設定)

---

## 📝 今後の拡張案 (MVP 後)

- 他のキーボード配列対応 (Corne, Lily58 など)
- QMK/VIA の JSON ファイルインポート機能
- タイマー・WPM 表示
- ランキング機能
- 単語の難易度別・カテゴリ別練習
- ダークモード
- キーボード描画の SVG 化

---

## ✅ 開発開始前チェックリスト

- [ ] Ruby 3.4.1 インストール確認
- [ ] Rails 8 インストール確認
- [ ] PostgreSQL インストール確認
- [ ] Google Cloud Console で OAuth 認証情報作成
- [ ] さくら VPS アクセス確認
- [ ] Git リポジトリ作成
- [ ] 独自ドメイン候補の確認・取得準備
