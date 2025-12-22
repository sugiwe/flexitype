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
- 作業完了後は、リモートにプッシュし PR を作成、人間の開発者が PR をマージし main ブランチに pull したのを確認してからブランチを削除
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

- キーマップ: DB に保存 (ユーザーごと、KeymapSet)
- 練習履歴: DB に保存（LessonRecord）
- レッスン: DB に保存（Category、Lesson - Day 21でYAMLから移行完了）
- UI 設定: LocalStorage (テーマ選択、デスクトップバナー表示状態など)

---

## 💡 実装済み機能

**詳細は `CLAUDE_FEATURES.md` に記載。**
実装が完了したら適宜 `CLAUDE_FEATURES.md` を更新していく。

### 主要機能の概要

1. ✅ **ユーザー認証**（Google Identity Services、メール許可リスト制）
2. ✅ **キーマップ管理**（複数管理、KeymapSet、slug 対応、6 レイヤー）
3. ✅ **タイピング練習**（レッスンシステム、指ガイド、レイヤー自動判定、2 段表示）
4. ✅ **練習履歴・統計**（自動クリーンアップ、レスポンシブ UI、ページネーション）
5. ✅ **レッスン管理**（Category・Lessonモデル、ユーザー作成レッスン、visible_toスコープ）
6. ✅ **管理者ダッシュボード**（ユーザー統計、人気レッスンランキング、詳細: `CLAUDE_ADMIN_DASHBOARD.md`）
7. ✅ **レスポンシブ対応**（モバイル・PC 両対応、ハンバーガーメニュー）
8. ✅ **ダークモード**（Light/Dark/System、LocalStorage 永続化）
9. ✅ **URL 構造整理**（RESTful 設計、`/my`名前空間、`/@username`プロフィール）
10. ✅ **ユーザー名機能**（`/@username`形式、Gmail 互換バリデーション）
11. ✅ **SEO/SNS 対応**（OGP、Twitter Card）
12. ✅ **セキュリティ強化**（Brakeman 0 警告、CSP 設定、Strong Parameters）
13. ✅ **本番環境デプロイ**（https://typnix.com、SSL/TLS、Kamal）

---

## 🗺️ URL 構造

### 設計方針

- 個人ページは `/my` 名前空間に統一
- ユーザープロフィールは `/@username` 形式で公開
- 管理者ページは `/admin` 名前空間

### URL 一覧

#### 公開ページ（認証不要）

- `/` - トップページ（レッスン一覧）
- `/lessons/:id` - レッスンページ（数値 ID ベース）
- `/@:username` - ユーザープロフィール
- `/terms` - 利用規約
- `/privacy` - プライバシーポリシー
- `/about` - About ページ

#### 個人ページ（認証必要、`/my`配下）

- `/my` - マイページ（設定ダッシュボード）
- `/my/account/edit` - アカウント設定（username 編集）
- `/my/keymaps` - キーマップ一覧
- `/my/keymaps/:slug/edit` - キーマップ編集
- `/my/lessons` - レッスン管理（課金ユーザー向け）
- `/my/history` - 練習履歴

#### 管理者ページ（認証+管理者権限必須、`/admin`配下）

- `/admin` - 管理者ダッシュボード
- `/admin/users` - ユーザー一覧
- `/admin/users/:id` - ユーザー詳細

#### 認証

- `POST /auth/google` - Google 認証
- `DELETE /logout` - ログアウト

---

## 🔒 セキュリティ・認証

- **CSRF 対策**: Rails 標準の CSRF 保護
- **環境変数管理**: `credentials.yml.enc`（Google Client ID/Secret）、`.kamal/secrets`（ALLOWED_EMAILS, ADMIN_EMAILS）
- **ID トークン検証**: `google-id-token` gem
- **Strong Parameters**: 全コントローラで適切に実装
- **セキュリティチェック**: Brakeman 0 警告、bundler-audit で定期的に検査
- **Content Security Policy (CSP)**: `config/initializers/content_security_policy.rb`
  - Google ログインとの競合を解消（nonce 無効化、`:unsafe_inline`有効化）
  - インラインスタイル（`style=`属性）は使用禁止

---

## 🚀 デプロイ構成

### さくら VPS

- Rails アプリ (Kamal 経由でコンテナデプロイ)
- PostgreSQL (VPS 内で直接稼働)

### 独自ドメイン

- ドメイン: typnix.com
- DNS: Cloudflare 経由
- SSL/TLS: Let's Encrypt (Kamal で自動設定、90 日ごとに自動更新)
- エンドツーエンド暗号化（ブラウザ → Cloudflare → VPS）

---

## 📦 主要データモデル

詳細は各モデルファイルおよび `CLAUDE_FEATURES.md` を参照。

- **User**: Google 認証、履歴制限、ログイン追跡、premium判定
- **KeymapSet**: キーマップセット（名前、説明、公開設定、slug、keyboard_type）
- **Keymap**: キー配置（レイヤー、位置、文字、keymap_set_id）
- **Category**: レッスンカテゴリー（名前、説明、表示順、published、requires_login、premium）
- **Lesson**: レッスン（user_id、category_id、items (JSONB)、is_public、visible_toスコープ、カテゴリーからrequires_login/premium継承）
- **LessonRecord**: 練習履歴（正答率、所要時間、ミス数、completed_at）

---

## 📅 開発スケジュール

### Phase 1-6: 完了（Day 1-16）

- **Phase 1**: 基盤構築（Day 1-3）
  - Rails 新規作成、Google 認証基本実装
- **Phase 2**: コア機能実装（Day 4-8）
  - タイピング練習、キーマップ登録・保存
- **Phase 3**: UX 向上・UI 改善（Day 9-12）
  - レッスンシステム、ダークモード、ベータ版 UI
- **Phase 4**: デプロイ（Day 13-14）
  - VPS 初回デプロイ、独自ドメイン・SSL 設定
- **Phase 5**: セキュリティ・レスポンシブ対応（Day 15）
  - Brakeman 0 警告、モバイル対応、OGP 設定
- **Phase 6**: 履歴機能（Day 16）
  - LessonRecord モデル、自動クリーンアップ、履歴一覧ページ

### Phase 7: ブラッシュアップ（Day 17-25、進行中）

- ✅ **Day 17**: URL 構造整理、ユーザー名機能（`/@username`）
- ✅ **Day 18**: KeymapSet 基盤実装、UI/UX 改善（詳細: `CLAUDE_KEYMAP_EXPANSION.md`）
- ✅ **Day 19**: Google ログイン修正、キーマップ UI 改善（slug 対応）
- ✅ **Day 20**: 管理者ダッシュボード実装 + Google AdSense 審査リクエスト + practice/session → lesson/lesson_record リファクタリング（詳細: `CLAUDE_ADMIN_DASHBOARD.md`, `CLAUDE_ADSENSE.md`）
- ✅ **Day 21**: レッスンDB化完了 + カテゴリー管理機能実装 + アーキテクチャ大幅改善（Category・Lessonモデル、権限フラグ整理、published機能、Admin::CategoriesController）
- 🔄 **Day 22**: ユーザーフィードバック対応（進行中）
  - ✅ キーマップリセット機能のバグ修正
  - ✅ キーマップ選択機能の実装（active_keymap_set_id）
  - ✅ タイピング練習時の操作説明改善（Delete キー説明追加）
  - ✅ レイアウトシフト問題の修正
  - 🔜 記号単体でのキーマップ設定（優先度：低、将来実装）
  - 🔜 数字や記号を含む練習問題の追加（Day 26以降で対応）
  - 🔜 キーマップインポート機能（Vial JSON対応、将来実装）
- 🔜 **Day 23**: トップページタブ化、成績評価システム、結果シェア機能（画像生成）
- 🔜 **Day 24**: 最終調整・リファクタリング
- 🔜 **Day 25**: 最終調整・ドキュメント整備

---

## 🎯 現在の進捗状況（Day 22 進行中）

### 完了した主要マイルストーン

- ✅ **Phase 1-6**: 基盤構築〜履歴機能（Day 1-16）
- ✅ **Day 17**: URL 構造整理、ユーザー名機能
- ✅ **Day 18**: KeymapSet 基盤実装（Phase 1）、UI/UX 改善
- ✅ **Day 19**: Google ログイン修正（Turbo 対応・CSP 競合解消）、キーマップ UI 改善
- ✅ **Day 20**: 管理者ダッシュボード実装（Phase 1-3 完了）、Google AdSense 審査リクエスト、practice/session → lesson/lesson_record リファクタリング
- ✅ **Day 21**: レッスンDB化完了 + カテゴリー管理機能完全実装 + アーキテクチャ大幅改善
  - Category・Lessonモデル作成とYAML移行
  - LessonLoader削除（Rails way化）
  - `/my/lessons` CRUD実装
  - Admin::CategoriesController 完全実装
  - 権限フラグの冗長性解消（delegate パターン）
  - published フラグによる公開制御
- 🔄 **Day 22**: ユーザーフィードバック対応（進行中）
  - ✅ キーマップリセット機能のバグ修正（早期リターンパターン）
  - ✅ キーマップ選択機能の実装（active_keymap_set_id、UI/UX改善）
  - ✅ タイピング練習時の操作説明改善（Delete キー説明追加）
  - ✅ レイアウトシフト問題の修正（min-height設定）
  - ✅ 本番環境デプロイ成功（マイグレーションエラー対応含む）

### 技術的マイルストーン

- Day 14: **独自ドメインデプロイ完了**（当初目標 25 日に対し 11 日前倒し）
- Day 15: **セキュリティ強化**（Brakeman 警告 0 件達成）
- Day 16: **履歴機能実装**（自動クリーンアップ）
- Day 17: **URL 構造整理**（RESTful 設計、数値 ID ベース）
- Day 18: **KeymapSet 基盤実装**（複数キーマップ管理の基礎完成）
- Day 19: **Google ログインバグ修正**（Turbo 対応、CSP 競合解消）
- Day 20: **管理者ダッシュボード実装 + Google AdSense 審査リクエスト + 用語統一リファクタリング**（practice/session → lesson/lesson_record）
- Day 21: **レッスンDB化完了 + カテゴリー管理機能完成 + アーキテクチャ改善**（Day 21-22の目標を1日で達成、delegate パターン活用、published 機能、本番環境データ移行の教訓）

### 次のステップ（Phase 7 以降）

#### Day 22-25: UX向上と機能拡張（詳細: `CLAUDE_LESSON_DB_PLAN.md`）

**Day 22**: テストユーザーのフィードバックを元に改善
- 🔜 実際のユーザーからのフィードバック収集
- 🔜 UI/UXの改善
- 🔜 バグ修正

**Day 23**: トップページタブ化、成績評価システム、結果シェア機能
- 🔜 トップページのタブ化（公式・自作・共有レッスン）
- 🔜 成績評価システム（4段階評価: プロ級、上級者、中級者、初心者）
- 🔜 結果シェア機能（HTML Canvas で画像生成）

**Day 24**: 最終調整・リファクタリング
- 🔜 パフォーマンス最適化（N+1 クエリなど）
- 🔜 コードリファクタリング
- 🔜 セキュリティチェック（Brakeman, bundler-audit）

**Day 25**: 最終調整・ドキュメント整備
- 🔜 最終バグ修正
- 🔜 ドキュメント整備（README、CHANGELOG など）
- 🔜 25日間の振り返り

#### その他の進行中タスク

- ⏳ **AdSense 審査**: 1〜2週間（審査通過後に広告配置を実装）
- ✅ **Google Analytics**: 導入済み（GTM + GA4）

---

## 📝 設計ドキュメント

### 実装完了

- **`CLAUDE_FEATURES.md`** - 実装済み機能の詳細仕様（随時更新）
- **`CLAUDE_ADMIN_DASHBOARD.md`** - 管理者ダッシュボード設計（✅ Day 20 完了）
- **`CLAUDE_KEYMAP_EXPANSION.md`** - キーマップ拡張設計（✅ Phase 1 完了、Phase 2-3 は将来実装）
- **`CLAUDE_ADSENSE.md`** - Google AdSense 導入設計（✅ Day 20 サイト所有権確認完了、審査中）

### 実装中（Day 21-25）

- **`CLAUDE_LESSON_DB_PLAN.md`** - レッスンDB化と機能拡張計画
  - ✅ Day 21: レッスンのDB化（YAML → PostgreSQL）完了
  - ✅ Day 21: ユーザー作成レッスン機能（`/my/lessons` CRUD）完了
  - ✅ Day 21: カテゴリー管理機能（Admin::CategoriesController）完了
  - 🔜 Day 22: テストユーザーのフィードバックを元に改善
  - 🔜 Day 23: トップページタブ化、成績評価システム、結果シェア機能
  - 🔜 Day 24: 最終調整・リファクタリング
  - 🔜 Day 25: 最終調整・ドキュメント整備

### 将来実装（Day 26以降）

- **`CLAUDE_KEYBOARD_TYPE_DESIGN.md`** - キーボードタイプ対応設計（Phase 0 完了、Phase 1 以降は将来実装）
- **`CLAUDE_WHITELIST_DESIGN.md`** - ホワイトリスト管理設計（保留中）

---

## 将来実装予定（Day 26以降）

### キーマップ機能の拡張

#### キーマップ公開機能（Phase 2-3）

詳細は `CLAUDE_KEYMAP_EXPANSION.md` を参照。

- キーマップ一覧ページ（`/my/keymaps`）
- 公開/非公開設定
- 他ユーザーの公開キーマップ閲覧（`/@username/keymaps`）
- フォーク機能（他ユーザーのキーマップをコピー）

#### キーマップ設定の充実

- ファンクションキー（F1-F12）の追加
- 修飾キー組み合わせ（Ctrl+C など）
- マウスキー、マクロ

#### ユーザーフィードバックから追加された機能要望

**記号単体でのキーマップ設定**
- **問題点**: 「!」「@」「-」「=」など、記号単体での設定ができない（現在は「1と!」のようなShiftペア前提）
- **影響度**: 中（キーマップの柔軟性）
- **実装方針**:
  - キーマップ編集UIに「記号単体」タブを追加
  - 2段表示（|デリミタ）を任意に設定できるようにする
  - 単体設定の場合は|なしで保存
  - 既存のShiftペア前提ロジックとの互換性を保つ
- **作業量**: 中（2-3時間）
- **優先度**: 低（将来実装）

**数字や記号を含む練習問題の追加**
- **問題点**: 現状、記号練習が不足している
- **影響度**: 低（後日のレッスン充実化で対応）
- **実装方針**:
  - Day 26以降の「管理者レッスン増加」フェーズで対応
  - `/my/lessons`でレッスンを作成済みなので、管理者が追加可能
  - 記号練習カテゴリーを拡充
- **作業量**: 小-中（レッスン作成は簡単、コンテンツ作成に時間）

**キーマップインポート機能**
- **問題点**: 既存のキーマップ（VialのJSONなど）からインポートできない
- **影響度**: 低（便利だが必須ではない）
- **実装方針**:
  - Phase 1: Vial JSONフォーマットの調査
  - Phase 2: JSONパーサーの実装
  - Phase 3: キーボードタイプごとのインポート機能
  - キーマップ編集画面に「JSONからインポート」ボタン追加
- **作業量**: 大（調査含めて1日以上）

### キーボードタイプ対応（Phase 1 以降）

詳細は `CLAUDE_KEYBOARD_TYPE_DESIGN.md` を参照。

- 複数のキーボードタイプに対応（Corne、Lily58、5x6配列など）
- KeyboardTypeモデルの作成
- JSONB型の`layout_data`カラムでキーボード情報を管理
- UI動的生成対応

### 課金スキーム設計と実装（Day 26-30 予定）

詳細は `CLAUDE_LESSON_DB_PLAN.md` を参照。

**技術スタック:**
- Stripe（決済処理）
- Subscription モデル（サブスクリプション管理）
- Webhook 処理（支払い成功/失敗の処理）

**無料/有料機能の分け方（案）:**
- 公式レッスン（基礎）: 無料 / 公式レッスン（全カテゴリ）: 有料
- キーマップ登録: 2つまで（無料） / 5つまで（有料）
- 練習履歴: 50件（無料） / 無制限（有料）
- 自作レッスン作成: 2つまで・非公開のみ（無料） / 5つまで・公開可能（有料）
- 統計グラフ: 有料のみ

### その他の拡張案

- エラーページの整備（404/500ページのカスタマイズ）
- 統計グラフ（正答率の推移など）
- ランキング機能
- 言語切り替え（多言語対応）

---

## 既知の問題（影響なし）

### Google ログインボタンのコンソール警告

**警告内容:**

```
[GSI_LOGGER]: Failed to render button before calling initialize().
```

**現状:**

- ✅ 機能的には全く問題なし（ログイン、ページ遷移、表示すべて正常）
- ⚠️ Google の内部処理で発生する警告（制御範囲外の可能性）
- 📝 重複初期化防止は実装済み（`data-google-signin-initialized`フラグ）

**対応状況:**

- Stimulus コントローラー（google_signin_controller.js）で適切に初期化を管理
- 警告自体は Google 側の内部処理によるもので、完全な解消は困難
- 機能に影響がないため、優先度は低い

---

## プロジェクトの成果

**達成状況:**

- ✅ 25 日間で独自ドメインへのデプロイ完了（Day 14 で達成、11 日前倒し）
- ✅ 主要機能（練習、キーマップ設定、履歴、レッスン管理、管理者ダッシュボード）がすべて完成
- ✅ セキュリティ、レスポンシブ対応、ダークモードなど、プロダクション品質のアプリケーション
- ✅ 本番環境で稼働中（https://typnix.com）
- ✅ Brakeman 0 警告達成
- ✅ レッスンDB化完了（YAMLからPostgreSQLへの完全移行）
- ✅ KeymapSet モデルの実装により、複数キーマップ管理の基盤が完成
- ✅ Rails wayなアーキテクチャ（LessonLoaderサービスオブジェクト削除、RESTful設計）

**技術的な成長:**

- Rails 8.1.1 の最新機能を活用
- Hotwire（Turbo + Stimulus）による快適な UX
- Kamal によるモダンなデプロイフロー
- セキュリティベストプラクティスの実践

---

このドキュメントは、プロジェクトの「インデックス」的な役割を果たします。
詳細な仕様や設計は、各専用ドキュメント（`CLAUDE_FEATURES.md`、`CLAUDE_ADMIN_DASHBOARD.md` など）を参照してください。
