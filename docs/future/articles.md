# Article機能（ブログ・ガイド記事）

AdSense審査対策とSEO強化のため、分割キーボード・タイピング関連の記事コンテンツを提供する。

---

## 目的

1. **AdSense審査対策**: 「有用性の低いコンテンツ」の問題を解決
2. **SEO強化**: 分割キーボード関連の検索流入を増やす
3. **ユーザー教育**: 初心者向けガイドで新規ユーザーを増やす
4. **コミュニティ形成**: 分割キーボードの情報ハブとなる

---

## URL設計

```
/articles                           # 記事一覧
/articles/typing-tips              # カテゴリ別一覧
/articles/what-is-split-keyboard   # 記事詳細（slug）
```

---

## データモデル

### Article モデル

```ruby
class Article < ApplicationRecord
  # カラム
  - title (string, not null)                 # タイトル
  - slug (string, unique, not null)          # URLスラッグ
  - content (text, not null)                 # 本文（Markdown）
  - excerpt (text)                           # 要約（一覧表示用）
  - category (integer, not null)             # カテゴリ（enum）
  - published_at (datetime)                  # 公開日時
  - author_id (references users, nullable)   # 著者（管理者のみ）
  - view_count (integer, default: 0)         # 閲覧数
  - created_at, updated_at

  # アソシエーション
  - belongs_to :author, class_name: "User", optional: true

  # バリデーション
  - validates :title, presence: true, length: { maximum: 100 }
  - validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  - validates :content, presence: true
  - validates :category, presence: true

  # スコープ
  - scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }
  - scope :recent, -> { order(published_at: :desc) }
  - scope :by_category, ->(category) { where(category: category) }

  # メソッド
  - def published?: published_at.present? && published_at <= Time.current
  - def to_param: slug
end
```

### カテゴリ設計

```ruby
enum category: {
  typing_tips: 0,      # タイピング技術
  keyboard_basics: 1,  # キーボード基礎知識
  keyboard_reviews: 2, # キーボードレビュー
  customization: 3,    # カスタマイズ
  typnix_guides: 4,    # Typnix使い方
  community: 5         # コミュニティ
}
```

---

## 記事アイデア（45+）

### 🎯 カテゴリA: タイピング技術・上達法（typing_tips）

1. **タイピング上達の基本 - 正しいホームポジションとは**
   - 初心者向け、SEO効果大
2. **タイピング速度を上げる5つのコツ**
   - 汎用的な価値提供、検索流入期待
3. **タイピング精度を高める練習方法**
   - Typnixの練習機能との連携
4. **疲れにくいタイピング姿勢のポイント**
   - 健康面での価値提供
5. **デスク環境の最適化 - 椅子と机の高さ調整**
   - エルゴノミクス関連
6. **手首の痛みを防ぐエルゴノミクス**
   - 分割キーボードのメリットと絡める
7. **レイヤー機能を使いこなす - 記号入力の効率化**
   - Typnixの強み
8. **ブラインドタッチ習得までのロードマップ**
   - 初心者向け、長期的な練習ガイド
9. **プログラマー向けタイピング最適化**
   - ターゲット層に響く
10. **日本語入力とローマ字入力の使い分け**
    - 将来の日本語対応と連携

### ⌨️ カテゴリB: キーボードの基礎知識（keyboard_basics）

11. **分割キーボードとは？メリット・デメリット** 🌟
    - 最優先、検索流入の入り口
12. **オーソリニア配列 vs カラムスタッガード配列** 🌟
    - 差別化ポイント
13. **垂直配列（オーソリニア）キーボード入門**
    - Typnixの対応キーボードと連携
14. **レイヤー機能とは？40%キーボードの使い方** 🌟
    - Typnix独自の強み
15. **キースイッチの種類と選び方（リニア・タクタイル・クリッキー）**
    - 購入検討者向け
16. **静音タイピングのためのキースイッチ選び**
    - ニッチだが需要がある
17. **キーキャップの素材と打鍵感の違い（PBT vs ABS）**
    - カスタマイズ入門
18. **自作キーボードの世界へようこそ**
    - コミュニティ誘導
19. **キーボードの接続方式（有線 vs 無線 vs Bluetooth）**
    - 購入検討者向け
20. **メカニカルキーボード vs 静電容量無接点方式**
    - 比較記事

### 🛠️ カテゴリC: 具体的なキーボード紹介（keyboard_reviews）

21. **Cornix徹底レビュー - 4×6分割型キーボード**
    - Typnix対応キーボード
22. **Corne（Crkbd）入門 - 人気の分割キーボード**
    - 人気キーボード紹介
23. **Lily58 レビュー - 数字キー付き分割キーボード**
    - 人気キーボード紹介
24. **Planck徹底ガイド - 40%オーソリニアキーボード**
    - Typnix対応キーボード（ortho_4x12）
25. **初心者におすすめの分割キーボード5選** 🌟
    - 商品紹介、アフィリエイト可能
26. **予算別 分割キーボード購入ガイド**
    - 購入検討者向け
27. **遊舎工房で買える分割キーボード比較**
    - 国内購入者向け
28. **海外通販で買える人気分割キーボード**
    - 海外通販ガイド

### 🔧 カテゴリD: カスタマイズ・設定（customization）

29. **キーマップカスタマイズの基本**
    - Typnixの機能と連携
30. **QMK Firmware入門 - キーマップの作り方**
    - 上級者向け
31. **VIA / Vialでキーマップを簡単カスタマイズ**
    - Vial連携機能の布石
32. **レイヤー設計のベストプラクティス**
    - Typnixの練習と連携
33. **自分だけの最適なキーマップを作る方法**
    - Typnixの機能紹介
34. **ModTapとは？修飾キーを効率的に配置する**
    - 上級者向け
35. **マクロ機能でタイピングを自動化**
    - QMK/Vial関連

### 📱 カテゴリE: Typnix使い方ガイド（typnix_guides）

36. **Typnixの使い方 - 初めてのタイピング練習** 🌟
    - サービス紹介、最優先
37. **キーマップ管理機能の使い方**
    - 独自機能の説明
38. **練習結果をシェアする方法**
    - シェア機能の紹介
39. **カワウソグレードシステムとは？目指せ伝説のカワウソ！**
    - 楽しさアピール
40. **効果的な練習スケジュールの立て方**
    - Typnixでの練習ガイド
41. **統計機能を活用した上達トラッキング**
    - 履歴機能の紹介

### 🌟 カテゴリF: コミュニティ・トレンド（community）

42. **分割キーボードコミュニティの歩き方**
    - Discord、Reddit紹介
43. **キーボード沼とは？ハマる前に知っておくべきこと**
    - ユーモア系
44. **2025年注目の分割キーボードトレンド**
    - トレンド記事
45. **海外キーボードコミュニティ（Reddit, Discord）紹介**
    - グローバル展開の布石

---

## 最初の10記事（優先度順）

AdSense審査を通すための最初の10記事：

### Phase 1: 基礎知識（SEO効果大）

1. **分割キーボードとは？メリット・デメリット** - 検索流入の入り口
2. **オーソリニア配列 vs カラムスタッガード配列** - 差別化ポイント
3. **レイヤー機能とは？40%キーボードの使い方** - Typnix独自の強み
4. **初心者におすすめの分割キーボード5選** - 商品紹介
5. **タイピング速度を上げる5つのコツ** - 汎用的な価値提供

### Phase 2: Typnix機能説明

6. **Typnixの使い方 - 初めてのタイピング練習** - サービス紹介
7. **キーマップ管理機能の使い方** - 独自機能
8. **カワウソグレードシステムとは？目指せ伝説のカワウソ！** - 楽しさ

### Phase 3: 実用的なガイド

9. **静音タイピングのためのキースイッチ選び** - ニッチだが需要がある
10. **手首の痛みを防ぐエルゴノミクス** - 健康面での価値提供

---

## 実装計画

### Phase 1: 基盤実装（1-2日）

1. Article モデル作成
2. 管理者画面CRUD（`/admin/articles`）
3. 公開ページ（`/articles`, `/articles/:slug`）
4. Markdownレンダリング

### Phase 2: 記事執筆（1-2週間）

1. 最初の10記事を執筆
2. 画像・スクリーンショット追加
3. SEO最適化（meta description, OGP）

### Phase 3: AdSense再審査（Phase 2完了後）

1. 10記事公開後、1週間程度様子見
2. Google Search Console登録
3. AdSense再審査申請

---

## SEO対策

### meta タグ

- title: 記事タイトル
- description: excerpt（要約）
- keywords: カテゴリ + 分割キーボード関連キーワード

### OGP

- og:title: 記事タイトル
- og:description: 要約
- og:image: アイキャッチ画像（将来実装）
- og:type: article

### サイトマップ

- `/sitemap.xml` に記事を含める
- Google Search Consoleに送信

---

## 将来の拡張

### アイキャッチ画像

- Active Storage導入
- 画像アップロード機能
- OGP画像自動生成

### コメント機能

- ユーザーからのフィードバック
- コミュニティ形成

### タグ機能

- 記事にタグ付け
- タグ別一覧ページ

### 検索機能

- 記事内全文検索
- キーワードハイライト

---

## 参考リンク

- [Markdown記法](https://www.markdownguide.org/)
- [SEOベストプラクティス](https://developers.google.com/search/docs)
- [AdSense コンテンツポリシー](https://support.google.com/adsense/answer/1348688)
