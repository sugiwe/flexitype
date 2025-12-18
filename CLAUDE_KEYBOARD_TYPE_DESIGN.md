# キーボードタイプ対応の拡張設計（Phase Y）

**作成日: 2025-12-18**
**ステータス: 設計案（未実装）**

## 現状の課題

- 現在は4x6（4行6列）の分割型配列が固定（Cornix専用）
- キーボードの物理形状・キー数がViewとYAMLファイルにハードコーディング
- 異なるキーボード（Corne、Lily58、5x6配列など）に対応できない
- キーの位置表記（`L0-R0`形式）がキーボード固有

## 将来の目標

- 複数のキーボードタイプに対応（Cornix、Corne、Lily58、5x6配列など）
- キーボードごとの物理配列情報をデータで管理
- ユーザーがキーマップ作成時にキーボードタイプを選択
- キーボードタイプに応じた練習画面・設定画面の自動生成

---

## データベース設計

### 新規モデル: KeyboardType

```ruby
class KeyboardType < ApplicationRecord
  has_many :keymap_sets, dependent: :restrict_with_error

  # カラム
  - name: string (max: 50, not null, unique) ← キーボード名（例: "Cornix 4x6", "Corne 3x6"）
  - display_name: string (max: 50, not null) ← 表示名（例: "Cornix（4×6）", "Corne（3×6+3親指）"）
  - description: text (max: 500, nullable) ← 説明
  - layout_data: jsonb (not null) ← レイアウト情報（JSON形式、後述）
  - is_active: boolean (default: true, not null) ← 有効フラグ
  - sort_order: integer (default: 0, not null) ← 表示順
  - created_at, updated_at

  # バリデーション
  - validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  - validates :display_name, presence: true, length: { maximum: 50 }
  - validates :layout_data, presence: true
  - validate :validate_layout_data_structure

  # スコープ
  - scope :active, -> { where(is_active: true).order(:sort_order) }

  # メソッド
  - def key_count: layout_dataから総キー数を計算
  - def finger_assignments: 指の割り当て情報を返す
end
```

### KeymapSet モデル（拡張）

```ruby
class KeymapSet < ApplicationRecord
  belongs_to :user
  belongs_to :keyboard_type  # ← NEW!
  has_many :keymaps, dependent: :destroy

  # 既存のカラム
  - user_id, name, description, is_public, forked_from_id, created_at, updated_at

  # 追加カラム
  - keyboard_type_id: references keyboard_types, not null ← NEW!

  # 追加バリデーション
  - validates :keyboard_type, presence: true

  # 追加メソッド
  - delegate :layout_data, :key_count, to: :keyboard_type
end
```

### Keymap モデル（変更なし）

- `key_position` カラムの形式がキーボードタイプごとに異なるが、文字列なので問題なし
- 例: Cornix → "L0-R0", Corne → "L0-C0", 5x6配列 → "L0-R0" など

---

## layout_data の JSON 構造設計

### 設計方針

- キーボードの物理的なレイアウト情報をすべて JSON で表現
- View 生成時にこの JSON を読み込んで動的にキーボードを描画
- 指の割り当て、カラムスタッガード（横ずれ）、キーサイズなども含む

### JSON スキーマ例（Cornix 4x6）

```json
{
  "version": "1.0",
  "keyboard_type": "split",
  "hands": {
    "left": {
      "columns": 6,
      "rows": 4,
      "keys": [
        {
          "position": "L0-R0",
          "row": 0,
          "col": 0,
          "finger": "left_pinky",
          "offset_x": 0,
          "offset_y": 0,
          "width": 1.0,
          "height": 1.0
        },
        {
          "position": "L0-R1",
          "row": 0,
          "col": 1,
          "finger": "left_ring",
          "offset_x": 0.25,
          "offset_y": 0,
          "width": 1.0,
          "height": 1.0
        }
        // ... 残りのキー
      ]
    },
    "right": {
      "columns": 6,
      "rows": 4,
      "keys": [
        // ... 右手側のキー定義
      ]
    }
  },
  "finger_colors": {
    "left_pinky": { "light": "bg-red-100", "dark": "bg-red-300" },
    "left_ring": { "light": "bg-yellow-100", "dark": "bg-yellow-300" },
    "left_middle": { "light": "bg-blue-100", "dark": "bg-blue-300" },
    "left_index": { "light": "bg-green-100", "dark": "bg-green-300" },
    "left_thumb": { "light": "bg-gray-100", "dark": "bg-gray-300" },
    "right_thumb": { "light": "bg-gray-100", "dark": "bg-gray-300" },
    "right_index": { "light": "bg-green-100", "dark": "bg-green-300" },
    "right_middle": { "light": "bg-blue-100", "dark": "bg-blue-300" },
    "right_ring": { "light": "bg-yellow-100", "dark": "bg-yellow-300" },
    "right_pinky": { "light": "bg-red-100", "dark": "bg-red-300" }
  }
}
```

### layout_data フィールドの説明

- `version`: スキーマバージョン（将来の互換性対応）
- `keyboard_type`: "split"（分割型）、"unibody"（一体型）など
- `hands`: 左手・右手ごとのキー配置情報
  - `columns`: 列数
  - `rows`: 行数
  - `keys`: 各キーの詳細情報
    - `position`: キー位置ID（ユニーク、Keymapモデルの `key_position` と対応）
    - `row`, `col`: グリッド上の行・列番号（0始まり）
    - `finger`: 担当する指（10種類: left_pinky, left_ring, ..., right_pinky）
    - `offset_x`, `offset_y`: カラムスタッガード用のオフセット（rem単位）
    - `width`, `height`: キーサイズ（通常は1.0、親指キーなどは1.5など）
- `finger_colors`: 指ごとの色定義（Tailwind CSSクラス）

### 他のキーボードタイプの例

#### Corne 3x6（3行6列 + 親指3キー）

```json
{
  "version": "1.0",
  "keyboard_type": "split",
  "hands": {
    "left": {
      "columns": 6,
      "rows": 4,
      "keys": [
        // 1-3行目: 通常のキー (L0-C0 ~ L2-C5)
        // 4行目: 親指キー3つ (L3-C3, L3-C4, L3-C5)
        { "position": "L3-C3", "row": 3, "col": 3, "finger": "left_thumb", "width": 1.5 }
      ]
    }
  }
}
```

#### 5x6配列（5行6列）

```json
{
  "version": "1.0",
  "keyboard_type": "split",
  "hands": {
    "left": {
      "columns": 6,
      "rows": 5,  // ← 行数が増える
      "keys": [
        // L0-R0 ~ L4-R5（5行分）
      ]
    }
  }
}
```

---

## UI/UX フロー

### キーマップ作成時

1. `/my/keymaps/new` で「新規キーマップ作成」をクリック
2. キーボードタイプ選択画面が表示
   - Cornix（4×6）、Corne（3×6+3親指）、Lily58（4×6+4親指）など
   - 各キーボードのプレビュー画像・説明を表示
3. キーボードタイプを選択して「次へ」
4. キーマップ名・説明を入力
5. キーマップ編集画面へ（選択したキーボードタイプのレイアウトで表示）

### キーマップ編集画面

- `keyboard_type.layout_data` を JavaScript に渡す
- JavaScript で動的にキーボードを描画
  - `keys` 配列をループして各キーを生成
  - `offset_x`, `offset_y` を CSS の `margin` で表現
  - `finger` に基づいて色分け
- 既存の Stimulus コントローラ（keymap_editor_controller.js）を拡張

### 練習画面

- 同様に `keyboard_type.layout_data` を使用
- 現在のハードコーディングされたキーボード描画を動的生成に置き換え
- `finger` 情報を使って指ガイド機能を実装

---

## URL設計（変更なし）

既存の URL 設計をそのまま活用：

```ruby
GET    /my/keymaps/new               # キーボードタイプ選択 → 新規作成フォーム
POST   /my/keymaps                   # 作成（keyboard_type_id を含む）
GET    /my/keymaps/:id/edit          # 編集（keyboard_typeに応じて動的にレイアウト生成）
PATCH  /my/keymaps/:id               # 更新
```

---

## 段階的な実装アプローチ

### Phase 0: UI準備（✅ 実装済み - Day 18）

**目的**: 将来の拡張を見据えて、今すぐ実装できる形でUIを準備

**実装内容**:
- キーマップ設定画面の上部に「キーボードタイプ選択」プルダウンを追加
- デフォルトで「4×6 - 分割型・オーソリニア」が選択済み
- 「今後、他のキーボードタイプの対応を予定しています」という案内を表示
- プルダウンは現時点では1つの選択肢のみ（機能的には無効化）

**設計方針**:
- キーボードタイプは開発側が管理（ユーザーが自由に追加できない）
- 「Lily58対応！」のようなお知らせと共に、徐々にキーボードタイプを増やす
- ユーザーに将来の拡張を予告し、期待感を持ってもらう

**ファイル変更**:
- `app/views/my/keymaps/edit.html.slim`: キーボードタイプ選択UIを追加

### Phase 0.5: 準備（KeymapSet 基盤整備後）

- KeymapSet 機能が完成してから着手
- 現状のハードコーディングされた UI を動的生成に置き換える実験

### Phase 1: KeyboardType モデルとマイグレーション

1. `keyboard_types` テーブルを作成
2. `keymap_sets` テーブルに `keyboard_type_id` カラムを追加
3. デフォルトの KeyboardType「Cornix 4x6」を作成
4. 既存の KeymapSet に `keyboard_type_id` を設定（全て Cornix）
5. `keyboard_type_id` を `NOT NULL` に変更

### Phase 2: UI の動的生成対応

1. `keymap_editor_controller.js` を拡張
   - `layout_data` を Stimulus の Value として受け取る
   - `layout_data.hands.left.keys` をループしてキーを動的生成
   - `offset_x`, `offset_y` を CSS で表現
2. `typing_controller.js` を拡張（練習画面のキーボード描画）
3. Slim テンプレートから `layout_data` を JavaScript に渡す

### Phase 3: キーボードタイプ選択 UI

1. `/my/keymaps/new` にキーボードタイプ選択画面を実装
2. KeyboardType の一覧をカード形式で表示
3. 選択後、キーマップ作成フォームへ遷移

### Phase 4: 他のキーボードタイプ追加

1. Corne 3x6 の `layout_data` を作成
2. Lily58、5x6配列など、順次追加
3. 各キーボードタイプのプレビュー画像を用意

---

## 実装時の注意点

### パフォーマンス

- `layout_data` は JSONB 型（PostgreSQL）で保存
- インデックスは不要（KeyboardType は数レコード程度）
- クライアント側でキャッシュして描画

### バリデーション

- `validate_layout_data_structure` で JSON スキーマをチェック
- 必須フィールド（`version`, `hands`, `finger_colors`）の存在確認
- `keys` 配列内の各キーが必須フィールドを持つことを確認

### デフォルトキーマップ

- 現在の `config/default_keymap.yml` は Cornix 専用
- キーボードタイプごとに別ファイルを用意
  - `config/default_keymaps/cornix_4x6.yml`
  - `config/default_keymaps/corne_3x6.yml`
- KeyboardType モデルに `default_keymap_path` カラムを追加（nullable）

### フォーク時の互換性

- フォーク元とフォーク先のキーボードタイプが異なる場合はエラー
- または、キーボードタイプを選択し直すフローを提供

### 既存データの移行

- 全ての KeymapSet は「Cornix 4x6」として扱う
- マイグレーション時に `keyboard_type_id` を自動設定

---

## 設計の利点

### 拡張性

- 新しいキーボードタイプの追加が容易（JSON を追加するだけ）
- QMK/VIA の JSON ファイルからインポートする機能も将来的に追加可能

### 保守性

- キーボードごとの View ファイルを個別に作成する必要がない
- 1つの動的生成ロジックで全キーボードに対応

### ユーザビリティ

- 自分のキーボードに合った練習ができる
- キーボードタイプごとの最適な指ガイド機能

### データ整合性

- KeyboardType は削除不可（`restrict_with_error`）
- KeymapSet と KeyboardType の関連が常に保たれる

---

## 将来的な拡張

### QMK/VIA JSON インポート

- QMK Configurator や VIA の JSON ファイルをアップロード
- `layout_data` に変換して KeyboardType を自動生成
- ユーザー独自のキーボードにも対応

### SVG キーボード描画

- より高度な視覚表現（キーキャップの形状、角度など）
- `layout_data` に SVG パスを含める

### キーボードタイプのコミュニティ投稿

- ユーザーが新しいキーボードタイプを投稿
- 管理者承認後に公開

---

## 関連ドキュメント

- [CLAUDE.md](./CLAUDE.md) - 開発仕様書（全体）
- [キーマップ機能の拡張設計](./CLAUDE.md#キーマップ機能の拡張設計phase-x) - CLAUDE.md内のキーマップ関連セクション
