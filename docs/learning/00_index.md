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

このリポジトリには**2種類の学習教材**があります：

### 📘 体系的な知識習得: Rails Application Development Guide

**[Rails Application Development Guide](guides/rails_application_development.md)**（全12章、約3500行）

Typnixプロジェクトの実装から抽出した、体系的なRails開発知識。リファレンスとしても使用可能。

**推奨される方:**
- Railsの全体像を体系的に理解したい
- 特定のトピック（Hotwire、セキュリティなど）を深く学びたい
- 実装中の参照資料として使いたい

**推定読了時間**: 2〜3時間（通し読み）、必要な章のみ参照も可

### 📗 トピック別学習: 個別教材とレビューテスト

実践的な個別トピックと、手を動かして学ぶレビューテスト。

**推奨学習順序:**

**中級編（実践的なパターン）**
1. [Concernパターン](topics/02_intermediate/01_concerns_pattern.md) - コードの共通化、DRY原則
2. [共通パーシャルの活用](topics/02_intermediate/02_shared_partials.md) - ビューの重複削減

**レビューテスト（実践問題）**
- [Review #01: Concernパターンの導入](reviews/review_01_concern_pattern.md)
- [Review #03: 共通パーシャル化](reviews/review_03_shared_partial.md)

**推定学習時間**: 各トピック 1〜2時間、レビューテスト 30分〜1時間

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
├── 00_index.md                              # 本ファイル（全体目次）
├── guides/                                  # 体系的ガイド
│   └── rails_application_development.md   # Rails開発ガイド（全12章、3500行）
├── topics/                                  # 個別トピック
│   ├── 01_basics/                          # 初級編（未作成）
│   ├── 02_intermediate/                    # 中級編
│   │   ├── 01_concerns_pattern.md
│   │   └── 02_shared_partials.md
│   └── 03_advanced/                        # 上級編（未作成）
└── reviews/                                 # レビューテスト
    ├── review_01_concern_pattern.md
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

### Rails Application Development Guide
- **通し読み**: 2〜3時間
- **特定章のみ参照**: 各10〜30分

### 個別トピックとレビューテスト
- **中級編トピック**: 各1〜2時間（全2トピック = 2〜4時間）
- **レビューテスト**: 各30分〜1時間（全2問 = 1〜2時間）

**合計（全教材）**: 5〜9時間

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

## 📚 教材一覧

### ガイド
- **[Rails Application Development Guide](guides/rails_application_development.md)** - Rails開発の体系的知識（全12章）
  - Chapter 1: Rails基礎とプロジェクト設計
  - Chapter 2: プロジェクト構造とディレクトリ設計
  - Chapter 3: データベース設計とモデル層
  - Chapter 4: ルーティングとURL設計
  - Chapter 5: コントローラーとビジネスロジック
  - Chapter 6: ビュー層の設計
  - Chapter 7: Hotwire (Turbo + Stimulus)
  - Chapter 8: 認証と認可
  - Chapter 9: テスト戦略
  - Chapter 10: セキュリティ
  - Chapter 11: デプロイと運用
  - Chapter 12: 保守とリファクタリング

### トピック
- **[Concernパターン](topics/02_intermediate/01_concerns_pattern.md)** - コードの共通化とDRY原則
- **[共通パーシャルの活用](topics/02_intermediate/02_shared_partials.md)** - ビューの重複削減

### レビューテスト
- **[Review #01: Concernパターンの導入](reviews/review_01_concern_pattern.md)** - PR形式の実践問題
- **[Review #03: 共通パーシャル化](reviews/review_03_shared_partial.md)** - DRY原則の実践

---

**最終更新**: 2025-12-30
**対応Railsバージョン**: Rails 8.1.1
**プロジェクト**: Typnix (Flexitype)
