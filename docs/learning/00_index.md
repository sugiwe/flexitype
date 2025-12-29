# Rails開発 実践ガイド - Flexitypeプロジェクトから学ぶ

## 📚 この教材について

このガイドは、Flexitypeプロジェクト（タイピング練習アプリ）の29日間の開発過程から抽出した、Ruby on Railsの実践的な学習教材です。

**特徴:**
- 実際に本番稼働しているアプリケーションのコード
- Day 1の基礎からDay 29の高度な実装まで、段階的な成長の軌跡
- 失敗からの改善、リファクタリングの過程が見える
- Rails 8.1.1 + Hotwire (Turbo + Stimulus) の最新構成

## 🎯 対象読者

- Railsの基本的な文法は理解しているが、実践的な設計パターンを学びたい方
- 「Rails way」な設計思想を身につけたい方
- リファクタリングの実例を見たい方
- 実際のプロダクトでどうコードを書くべきか知りたい方

## 📖 学習の進め方

### 推奨学習順序

**初級編（Rails規約の基礎）**
1. [Rails規約の基礎](01_basics/01_rails_conventions.md) - RESTful設計、命名規則
2. [MVC設計の実践](01_basics/02_mvc_architecture.md) - コントローラー、モデル、ビューの役割分担
3. [ルーティング設計](01_basics/03_routing_basics.md) - URL構造、名前空間

**中級編（実践的なパターン）**
4. [Concernパターン](02_intermediate/01_concerns_pattern.md) - コードの共通化、DRY原則
5. [共通パーシャルの活用](02_intermediate/02_dry_principle.md) - ビューの重複削減
6. [Turbo Framesの活用](02_intermediate/03_turbo_frames.md) - モダンなSPA風UI
7. [認証の実装](02_intermediate/04_authentication.md) - Google認証、ゲストユーザーパターン

**上級編（アーキテクチャ設計）**
8. [リファクタリングパターン](03_advanced/01_refactoring_patterns.md) - 実際の改善事例
9. [フィーチャーフラグ](03_advanced/02_feature_flags.md) - 削除容易性の確保
10. [データベースマイグレーション戦略](03_advanced/03_database_migrations.md) - 3段階アプローチ
11. [セキュリティベストプラクティス](03_advanced/04_security_practices.md) - Brakeman 0警告達成

**レビューテスト（実践問題）**
- [Review #01: Concernパターンの導入](04_reviews/review_01_concern_pattern.md)
- [Review #02: コントローラー命名の統一](04_reviews/review_02_controller_naming.md)
- [Review #03: 共通パーシャル化](04_reviews/review_03_shared_partial.md)

## 🗂️ 教材の構成

各教材は以下の構成で統一されています：

```markdown
# [トピック名]

## 🎯 学習目標
この教材を学ぶことで何ができるようになるか

## 📚 前提知識
必要な予備知識

## 📖 本編
### 概要
問題の背景、解決したい課題

### 実装前（アンチパターン）
改善前のコード

### 実装後（ベストプラクティス）
改善後のコード

### 解説
なぜこの設計が優れているのか

## 💡 まとめ
重要ポイントの要約

## 🔗 関連教材
関連する教材へのリンク

## 📝 演習問題（オプション）
理解度チェック
```

## 📂 ディレクトリ構造

```
docs/learning/
├── 00_index.md                    # 本ファイル（全体目次）
├── 01_basics/                     # 初級編
│   ├── 01_rails_conventions.md
│   ├── 02_mvc_architecture.md
│   └── 03_routing_basics.md
├── 02_intermediate/               # 中級編
│   ├── 01_concerns_pattern.md
│   ├── 02_dry_principle.md
│   ├── 03_turbo_frames.md
│   └── 04_authentication.md
├── 03_advanced/                   # 上級編
│   ├── 01_refactoring_patterns.md
│   ├── 02_feature_flags.md
│   ├── 03_database_migrations.md
│   └── 04_security_practices.md
└── 04_reviews/                    # レビューテスト
    ├── review_01_concern_pattern.md
    ├── review_02_controller_naming.md
    └── review_03_shared_partial.md
```

## 🎓 レビューテストの使い方

レビューテストは「あるあるなツッコミどころのあるPR」を想定した実践的な問題集です。

**進め方:**
1. PR概要と変更内容を確認
2. 問題点を自分で考える（3〜5分）
3. 改善策を考える（5〜10分）
4. 模範解答を確認
5. 実際のコードと比較

**難易度:**
- 🟢 初級: Rails規約の基礎的な知識
- 🟡 中級: 設計パターンの理解
- 🔴 上級: アーキテクチャレベルの判断

## 📊 学習時間の目安

- **初級編**: 各30分〜1時間（全3トピック = 1.5〜3時間）
- **中級編**: 各1〜2時間（全4トピック = 4〜8時間）
- **上級編**: 各2〜3時間（全4トピック = 8〜12時間）
- **レビューテスト**: 各30分〜1時間（全3問 = 1.5〜3時間）

**合計**: 15〜26時間

## 🔗 関連リソース

### プロジェクト内
- [CLAUDE.md](/CLAUDE.md) - プロジェクト全体の仕様書
- [日報](/docs/daily_reports/) - 29日間の開発記録
- [CLAUDE_FEATURES.md](/CLAUDE_FEATURES.md) - 実装済み機能の詳細

### 外部リソース
- [Rails公式ガイド](https://guides.rubyonrails.org/)
- [Hotwire公式ドキュメント](https://hotwired.dev/)
- [RuboCop Style Guide](https://rubocop.org/)

## 💬 フィードバック

教材の改善提案や質問は、GitHubのIssueでお願いします。

---

**最終更新**: 2025-12-29
**対応Railsバージョン**: Rails 8.1.1
**プロジェクト**: Typnix (Flexitype)
