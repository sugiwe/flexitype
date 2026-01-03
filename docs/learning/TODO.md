# 学習教材 制作管理

最終更新: 2025-12-30

---

## 📝 テンプレート使用方法

### トピック作成

1. `_templates/topic_template.md` の内容をコピー
2. `topics/XX_level/XX_topic_name.md` として保存
3. 【】で囲まれた部分を埋める
4. 参照日報を確認してコード例を抽出
5. 実装前後の比較、コード削減効果を明記

### レビューテスト作成

1. `_templates/review_template.md` の内容をコピー
2. `reviews/review_XX_topic_name.md` として保存
3. 【】で囲まれた部分を埋める
4. 4段階の難易度で質問を作成（🟢→🟡→🟡🔴→🔴）
5. PR形式で「ツッコミどころのあるコード」を提示

### ファイル命名規則

**トピック:**
- 初級: `topics/01_basics/XX_topic_name.md`
- 中級: `topics/02_intermediate/XX_topic_name.md`
- 上級: `topics/03_advanced/XX_topic_name.md`

**レビューテスト:**
- `reviews/review_XX_topic_name.md` (XXは連番、トピック番号と揃える)

---

## ✅ 完成済み

### 中級編
- [x] **01: Concernパターン** (Day 29, PR #101)
  - トピック: `topics/02_intermediate/01_concerns_pattern.md`
  - レビュー: `reviews/review_01_concern_pattern.md`
  - 学習時間: 1-2時間 + レビュー30分-1時間

- [x] **02: 共通パーシャルの活用** (Day 29, PR #101)
  - トピック: `topics/02_intermediate/02_shared_partials.md`
  - レビュー: `reviews/review_02_shared_partial.md`
  - 学習時間: 1-2時間 + レビュー30分-1時間

- [x] **03: Hotwire（Turbo Frames + Stimulus）** (Day 9, 19, 22, 24, 28, PR #94, #96, #101)
  - トピック: `topics/02_intermediate/03_hotwire.md` (約1,880行)
  - レビュー: `reviews/review_03_hotwire.md` (約680行)
  - 学習時間: 2-3時間 + レビュー30分-1時間

- [x] **04: データベース設計とマイグレーション戦略** (Day 21, 24)
  - トピック: `topics/02_intermediate/04_database_design.md` (約880行)
  - レビュー: `reviews/review_04_database_design.md` (約850行)
  - 学習時間: 2-3時間 + レビュー30分-1時間

- [x] **05: RESTfulなURL設計とルーティング** (Day 17)
  - トピック: `topics/02_intermediate/05_restful_url_design.md` (約830行)
  - レビュー: `reviews/review_05_restful_url_design.md` (約780行)
  - 学習時間: 1.5-2時間 + レビュー30分-1時間

- [x] **06: セキュリティベストプラクティス** (Day 3, 19, 24)
  - トピック: `topics/03_advanced/06_security_best_practices.md` (約1,120行)
  - レビュー: `reviews/review_06_security_best_practices.md` (約880行)
  - 学習時間: 2.5-3時間 + レビュー30分-1時間

- [x] **07: ActiveRecordスコープの効果的な使い方** (Day 20, 21)
  - トピック: `topics/02_intermediate/07_active_record_scopes.md` (約2,000行)
  - レビュー: `reviews/review_07_active_record_scopes.md` (約800行)
  - 学習時間: 1.5-2時間 + レビュー30分-1時間

### 上級編

- [x] **08: RSpecによるテスト戦略** (Day 25, 26, 27)
  - トピック: `topics/03_advanced/08_rspec_testing_strategy.md` (約1,388行)
  - レビュー: `reviews/review_08_rspec_testing_strategy.md` (約1,040行)
  - 学習時間: 2.5-3時間 + レビュー30分-1時間

- [x] **09: フィーチャーフラグパターン** (Day 28)
  - トピック: `topics/03_advanced/09_feature_flag_pattern.md` (約1,260行)
  - レビュー: `reviews/review_09_feature_flag_pattern.md` (約823行)
  - 学習時間: 1.5-2時間 + レビュー30分-1時間

- [x] **10: アーキテクチャ改善とリファクタリング** (Day 20, 21)
  - トピック: `topics/03_advanced/10_architecture_refactoring.md` (約1,041行)
  - レビュー: `reviews/review_10_architecture_refactoring.md` (約711行)
  - 学習時間: 2-3時間 + レビュー30分-1時間

- [x] **11: Kamalによるモダンなデプロイフロー** (Day 13, 14)
  - トピック: `topics/03_advanced/11_kamal_deployment.md` (約1,312行)
  - レビュー: `reviews/review_11_kamal_deployment.md` (約1,018行)
  - 学習時間: 2-3時間 + レビュー30分-1時間

---

## 🚧 制作中

現在制作中のトピックはありません。

---

## 📋 制作待ち（優先度順）

---

### 次フェーズ（0個）

すべての優先トピックが完成しました。

---

### 将来的に追加検討（10-15個）

#### 12: ユーザーフィードバック駆動開発
- **難易度**: 🟡 中級〜上級
- **参照日報**: Day 22, Day 27
- **学習ポイント**: キーマップバグ修正3件、ベータテストの価値

---

#### 13: データ移行の本番環境での教訓
- **難易度**: 🔴 上級
- **参照日報**: Day 21
- **学習ポイント**: 本番データ消失と復旧、Rakeタスク化

---

#### 14: View-Firstな開発アプローチ
- **難易度**: 🟢 初級
- **参照日報**: Day 4, Day 5
- **学習ポイント**: 先にビューを作る開発手法、Tailwind CSS活用

---

#### 15: Rails標準の認証機能実装
- **難易度**: 🟢 初級〜中級
- **参照日報**: Day 2, Day 3
- **学習ポイント**: DeviseなしのGoogle認証、セッション管理

---

## 📊 進捗状況

- **完成**: 11個（中級6、上級5）
- **制作中**: 0個
- **制作待ち（次フェーズ）**: 0個
- **将来検討**: 4個（初級2、中級1、上級1）

**合計**: 15個のトピック候補（優先11個は全て完成）

---

## 🎯 次のアクション

**優先11個のトピック制作が全て完了しました！**

将来的に追加検討するトピック（12-15番）は、必要に応じて制作してください。

---

## 📝 作業ログ

### 2025-12-30
- テンプレート作成（topic_template.md、review_template.md）
- TODO.md作成
- 15個のトピック候補を洗い出し
- 優先度付け完了
- **03: Hotwire 完成**（トピック約1,880行、レビュー約680行）
  - 3つのパターン解説（サーバーサイド管理、Stimulus管理、Turbo Streams）
  - Day 9, 19, 22, 24, 28の実例を豊富に引用
  - Google認証との統合トラブルシューティング含む
- **07: ActiveRecordスコープ 完成**（トピック約2,000行、レビュー約800行）
  - `visible_to(user)`スコープによる権限管理（Day 21）
  - N+1クエリ対策と`includes`/`joins`の使い分け（Day 20）
  - スコープチェーンと複雑なクエリの実装
  - コード削減率95%、SQL削減率97%の実例
- **04: データベース設計とマイグレーション戦略 完成**（トピック約880行、レビュー約850行）
  - 3段階マイグレーション戦略（クリーンアップ→型変更→制約追加）
  - JSONB型の活用（itemsカラム）
  - PostgreSQLの型キャスト（`using: 'lesson_id::bigint'`）
  - 外部キー制約とインデックスのセット運用
  - 本番環境でのデータ消失事故と教訓（Day 21）
- **05: RESTfulなURL設計とルーティング 完成**（トピック約830行、レビュー約780行）
  - `/my`名前空間による個人ページ整理（DRY原則）
  - `/@username`形式のプロフィールURL（ユーザーフレンドリー）
  - 数値IDベースの単純な設計（YAGNI原則）
  - controller:オプションの活用（URLとコントローラー名の分離）
  - Gmail互換バリデーション、24時間変更制限（Day 17）
- **06: セキュリティベストプラクティス 完成**（トピック約1,120行、レビュー約880行）
  - CSP設定とGoogle SDKとの競合解消（Day 3, 19）
  - 予約語システムによるルーティング保護（100+の予約語、Day 24）
  - ユーザー名変更制限（24時間冷却期間、Day 24）
  - Brakeman 0警告の継続的維持（Day 3）
  - セキュリティとUXのトレードオフ、OWASP Top 10対応
- **08: RSpecによるテスト戦略 完成**（トピック約1,388行、レビュー約1,040行）
  - RSpec環境セットアップとGemfileの構成（Day 25）
  - FactoryBotパターン（build vs create、sequence、traits）
  - モデルテスト（User、LessonRecord、AllowedEmail）
  - システムテスト（認証フロー、レッスン実行、履歴閲覧）
  - 「あるべき姿」のテスト哲学（テストが通らない→実装を修正、Day 26-27）
  - プラグマティックなアプローチ（80-90%優先、複雑なテストはskip + TODO）
  - 技術的負債管理（skip理由の明確化、解決策の記録）
- **09: フィーチャーフラグパターン 完成**（トピック約1,260行、レビュー約823行）
  - フィーチャーフラグの3つのメリット（段階的リリース、即座のロールバック、A/Bテスト）
  - RESTRICT_LOGIN環境変数によるON/OFF制御（Day 28）
  - ApplicationController#logged_in?での一元管理
  - 削除容易性を確保した設計（3段階削除手順、10ファイル）
  - ALLOWED_EMAILSのDB化（環境変数→PostgreSQL）
  - AllowedEmailモデル実装（バリデーション、正規化、.allowed?メソッド）
  - 環境変数 vs DB管理の2層アプローチと判断基準
  - RSpecテストでの環境変数モック（allow().to receive().and_return()）
- **10: アーキテクチャ改善とリファクタリング 完成**（トピック約1,041行、レビュー約711行）
  - 用語統一リファクタリング（practice/session → lesson/lesson_record、Day 20）
  - LessonLoader削除とRails wayへの回帰（サービスオブジェクト→ActiveRecord）
  - delegateパターンによる権限フラグ冗長性解消（requires_login, premium）
  - publishedフラグによる公開制御（Category.published、Day 21）
  - YAMLからDBへの移行戦略（3段階マイグレーション）
  - Admin::CategoriesController CRUD実装
  - サービスオブジェクトを使うべき時・使わない時の判断基準
- **11: Kamalによるモダンなデプロイフロー 完成**（トピック約1,312行、レビュー約1,018行）
  - Kamalによるゼロダウンタイムデプロイ（ヘルスチェック、ローリングアップデート）
  - config/deploy.yml の完全解説（さくらVPS、kamal-proxy、env設定）
  - SSL/TLS自動化（Let's Encrypt、証明書自動更新、Cloudflare統合）
  - Docker ベースのデプロイ戦略（イメージビルド、レジストリ、コンテナ管理）
  - .kamal/secrets の管理（RAILS_MASTER_KEY、POSTGRES_PASSWORD、KAMAL_REGISTRY_PASSWORD）
  - Day 13-14の初回デプロイ実装（PostgreSQL設定、環境変数移行、トラブルシューティング）
  - Kamalコマンド体系（deploy、envify、app exec、logs、rollback）
  - VPSセットアップ手順（Docker/Git/PostgreSQLインストール、ファイアウォール設定）
  - デプロイフロー最適化（並列実行、キャッシュ活用、ビルド時間短縮）
  - **優先11個のトピック制作が全て完了**
