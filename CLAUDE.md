# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# タイピング練習アプリ 開発仕様書

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

- Ruby: 3.4.1
- Rails: 8.x (最新)
- データベース: PostgreSQL
- 認証: OmniAuth + Google OAuth2 (Devise は使わない)

### フロントエンド

- 基本: HTML + CSS (固定レイアウト、横 1200px 想定)
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
- OmniAuth + `omniauth-google-oauth2` + `omniauth-rails_csrf_protection`
- セッション管理でログイン状態を保持

User モデル:

ruby

```ruby
# 必須カラム
- google_uid (string, unique)
- email (string)
- name (string)
```

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

#### レイヤー自動判定

- アプリが次に打つ文字を解析
- ユーザーのキーマップから「どのレイヤーに配置されているか」を判定
- 該当レイヤーのキーマップ表示に自動切り替え

#### ヒント表示 ON/OFF

- Stimulus でページ遷移なく切り替え
- 設定は LocalStorage に保存 (次回訪問時も反映)

---

### 5. 練習履歴・統計 (後期実装)

- 練習日時、単語数、正答率などを DB 保存
- 履歴一覧ページ
- 統計グラフ (正答率の推移など)

---

## 📅 開発スケジュール (25 日間)

### Phase 1: 基盤構築 (Day 1-2)

- Rails 新規作成、Git 初期化
- Google ログイン実装 (OmniAuth)
- User モデル作成

### Phase 2: コア機能実装 (Day 3-10)

- Day 3-5: 単語表示、タイピング判定ロジック、BackSpace 対応
- Day 6-8: キーボード描画 (CSS Grid)、リアルタイムハイライト
- Day 9-10: キーマップ登録・保存機能 (レイヤー対応)

### Phase 3: UX 向上 (Day 11-13)

- ヒント表示 ON/OFF 機能 (Stimulus)
- セッション完了画面
- レイヤー自動判定・2 箇所ハイライト

### Phase 4: 履歴機能 (Day 14-16)

- 練習履歴の DB 保存
- 履歴一覧ページ
- 簡易統計表示

### Phase 5: デプロイ (Day 17-20)

- Kamal セットアップ
- さくら VPS への初回デプロイ
- PostgreSQL セットアップ (VPS 内)
- 独自ドメイン取得・設定

### Phase 6: ブラッシュアップ (Day 21-25)

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

- CSRF 対策: `omniauth-rails_csrf_protection`
- 環境変数管理: `credentials.yml.enc` または dotenv
- Google OAuth Client ID/Secret は環境変数で管理

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
