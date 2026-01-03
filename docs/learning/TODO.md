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

### 次フェーズ（初級編: 10個）

初級者向けの「小粒だけど重要」な基礎トピック。各トピックにレビューテスト付き。

---

#### B1: Railsのルーティング設計
- **難易度**: 🟢 初級
- **参照日報**: Day 2, Day 17
- **推定作成時間**: 1-1.5時間（トピック + レビュー）
- **学習ポイント**:
  - RESTful設計の基本（`resources`、`only`、`except`）
  - 名前空間（`namespace :my`、`namespace :admin`）
  - カスタムルート（`get "/@:username"`）
  - パラメータ制約（`constraints: { username: /[^\/]+/ }`）
- **コード例**: `config/routes.rb`の設計パターン

---

#### B2: Railsのセッション管理
- **難易度**: 🟢 初級
- **参照日報**: Day 2-3
- **推定作成時間**: 1-1.5時間
- **学習ポイント**:
  - `session[:user_id]`でのセッション保存・取得
  - `session.delete(:user_id)`でのログアウト
  - メモ化（`@current_user ||=`）によるDB問い合わせ削減
  - セッションハイジャック対策
- **コード例**: ログイン/ログアウト機能、`current_user`メソッド

---

#### B3: helper_methodの活用
- **難易度**: 🟢 初級
- **参照日報**: Day 2-3
- **推定作成時間**: 1時間
- **学習ポイント**:
  - `ApplicationController`で`helper_method :current_user`を宣言
  - ビューでコントローラーのメソッドを使えるようにする
  - `private`メソッドでもビューから呼び出し可能
- **コード例**: `current_user`, `logged_in?`メソッドのビュー共有

---

#### B4: マイグレーションファイルの基本
- **難易度**: 🟢 初級
- **参照日報**: Day 2, Day 6, Day 12
- **推定作成時間**: 1-1.5時間
- **学習ポイント**:
  - `rails generate migration`の使い方
  - `add_column`, `add_index`, `add_reference`
  - `change`メソッドと`up/down`メソッドの使い分け
  - インデックスの作成（`unique: true`、複合インデックス）
- **コード例**: カラム追加、インデックス追加

---

#### B5: nil安全性とRubyのベストプラクティス
- **難易度**: 🟢 初級
- **参照日報**: Day 7
- **推定作成時間**: 1-1.5時間
- **学習ポイント**:
  - `present?`と`blank?`の違い
  - `to_s`による安全な文字列変換
  - 早期リターン（early return）パターン
  - セーフナビゲーション演算子（`&.`）
- **コード例**: nil対策パターン、メソッドチェーン

---

#### B6: ActiveRecordのバリデーション
- **難易度**: 🟢 初級
- **参照日報**: Day 2, Day 6, Day 12
- **推定作成時間**: 1-1.5時間
- **学習ポイント**:
  - `validates`の基本（`:presence`, `:uniqueness`, `:length`, `:numericality`）
  - カスタムバリデーション（`validate :method_name`）
  - `inclusion`（値の範囲チェック）
  - スコープ付きユニークネス（`scope: :user_id`）
- **コード例**: Userモデル、Keymapモデルのバリデーション

---

#### B7: Rails Credentialsの使い方
- **難易度**: 🟢 初級
- **参照日報**: Day 3
- **推定作成時間**: 1時間
- **学習ポイント**:
  - `config/credentials.yml.enc`での機密情報管理
  - `EDITOR="vim" rails credentials:edit`でのファイル編集
  - `Rails.application.credentials.dig(:google, :client_id)`での値取得
  - `config/master.key`の`.gitignore`管理
- **コード例**: Google OAuth Client IDの暗号化保存

---

#### B8: Slimテンプレートエンジンの基本
- **難易度**: 🟢 初級
- **参照日報**: Day 2, Day 4, Day 12
- **推定作成時間**: 1時間
- **学習ポイント**:
  - インデントベースの構文
  - `div.class-name`のショートカット
  - `=`（エスケープあり）と`==`（エスケープなし）の違い
  - Rubyコードの埋め込み（`- if condition`）
- **コード例**: ビューファイルの基本構造

---

#### B9: Tailwind CSSのクラス設計
- **難易度**: 🟢 初級
- **参照日報**: Day 4, Day 10, Day 11
- **推定作成時間**: 1-1.5時間
- **学習ポイント**:
  - ユーティリティファーストの思想
  - レスポンシブクラス（`md:`, `lg:`）
  - ダークモードクラス（`dark:`）
  - Flexbox/Grid レイアウト
- **コード例**: レスポンシブレイアウト、ダークモード対応

---

#### B10: Turboの挙動とdata-turbo="false"
- **難易度**: 🟢 初級
- **参照日報**: Day 3, Day 9
- **推定作成時間**: 1時間
- **学習ポイント**:
  - Rails 8のTurboはデフォルト有効
  - 外部JavaScriptとの連携時の問題
  - `data-turbo="false"`で従来の遷移に戻す
  - Google Identity Servicesなどとの競合解決
- **コード例**: ログアウトボタン、ホームリンクへの適用

---

### 将来的に追加検討（応用テクニック: 5個）

優先度低。必要に応じて制作。

---

#### B11: Stimulusコントローラーの基本
- **難易度**: 🟢 初級
- **参照日報**: Day 5, Day 6, Day 11
- **学習ポイント**: `data-controller`, `data-action`, `data-target`, イベントハンドリング

---

#### B12: LocalStorageでの設定永続化
- **難易度**: 🟢 初級
- **参照日報**: Day 11, Day 15
- **学習ポイント**: `localStorage.setItem/getItem`, FOUC防止

---

#### B13: YAMLファイルでのデータ管理
- **難易度**: 🟢 初級
- **参照日報**: Day 7, Day 9
- **学習ポイント**: `YAML.load_file`, メモ化パターン

---

#### B14: content_tagヘルパーの安全なHTML生成
- **難易度**: 🟢 初級
- **参照日報**: Day 8
- **学習ポイント**: XSS対策、`==`と`=`の違い

---

#### B15: 環境変数の使い分け
- **難易度**: 🟢 初級
- **参照日報**: Day 3, Day 14
- **学習ポイント**: `ENV["VARIABLE"]`, `.kamal/secrets` vs `config/deploy.yml`

---

### その他の将来検討トピック

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
- **難易度**: 🟡 中級
- **参照日報**: Day 4, Day 5
- **学習ポイント**: 先にビューを作る開発手法、Tailwind CSS活用

---

## 📊 進捗状況

- **完成**: 11個（中級6、上級5）
- **制作中**: 0個
- **制作待ち（次フェーズ）**: 10個（初級10）
- **将来検討**: 8個（初級応用5、中級2、上級1）

**合計**: 29個のトピック候補
- **優先トピック完成**: 11個（中級6、上級5）
- **次フェーズ**: 10個（初級編B1-B10、各トピック + レビューテスト）
- **低優先度**: 8個（応用テクニックB11-B15、その他12-14）

---

## 🎯 次のアクション

**優先11個のトピック制作が全て完了しました！**

次は初級編（B1-B10）の制作を開始してください。

### 制作開始時の手順

1. **トピック選択**: `B1: Railsのルーティング設計` から順に制作
2. **テンプレート使用**: `_templates/topic_template.md` と `_templates/review_template.md` を使用
3. **参照日報**: 各トピックの「参照日報」を確認（Day 2, Day 17など）
4. **ファイル命名**:
   - トピック: `topics/01_basics/B01_routing_design.md`
   - レビュー: `reviews/review_B01_routing_design.md`
5. **完成後**: TODO.mdの「完成」セクションに移動、00_index.mdを更新

### 初級編の特徴

- **対象読者**: Rails初心者（基本文法は理解している前提）
- **分量**: 各トピック 500-800行、レビュー 400-600行（中級より短め）
- **難易度**: 🟢 初級（全トピック統一）
- **レビューテスト形式**: 3段階（基礎 → 応用 → 実践）、4段階の中級編より1段階少ない

### コンテキスト引き継ぎ情報

**日報からの抽出パターン（2025-12-30に実施）:**
- Typnixプロジェクトの日報（Day 1-15）を重点的に分析
- 「小粒だけど重要」な実装パターンを15個抽出
- 優先度順に並べ替え（Rails基礎 → Ruby基礎 → フロントエンド → 応用）
- 10個に絞り込み（B1-B10）、残り5個は低優先度（B11-B15）

**テンプレート構成:**
- トピック: 学習目標 → 前提知識 → 本編（概要・実装前後・解説） → まとめ → 関連教材 → 演習問題
- レビュー: PR形式、4段階質問（初級は3段階に調整）、総合評価 → 次のステップ

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
- **初級編トピック候補の洗い出し完了**（2025-12-30）
  - Typnixプロジェクト日報（Day 1-15）を分析
  - 「小粒だけど重要」な基礎パターンを15個抽出
  - 優先10個（B1-B10）と低優先5個（B11-B15）に分類
  - 各トピックに学習ポイント、参照日報、推定作成時間を記載
  - 初級編の特徴を定義（分量500-800行、3段階レビュー形式）
