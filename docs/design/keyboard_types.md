# キーボードタイプ設計

分割型・一体型など、複数のキーボードレイアウトに対応するための設計ドキュメント。

---

## 実装方針

### シンプル実装方式を採用

当初はDBモデル（KeyboardType）を使った複雑なJSONBベースの設計を予定していたが、より**シンプルで保守性の高いアプローチ**を採用。

**メリット:**
- ✅ シンプル: DBモデル不要、マイグレーション不要
- ✅ 高速: 設定ファイルはRails起動時にロード済み
- ✅ 保守性: コード変更だけで新タイプ追加可能
- ✅ 型安全: Rubyのハッシュで厳密に定義
- ✅ バージョン管理: Gitで変更履歴を追跡可能

---

## アーキテクチャ

### 1. 設定ファイル

[config/initializers/keyboard_types.rb](../../config/initializers/keyboard_types.rb)

```ruby
KEYBOARD_TYPES = {
  "split_4x6" => {
    name: "4×6分割型（オーソリニア）",
    name_en: "4×6 Split (Ortholinear)",
    grid_type: :split,
    rows_left: 4, cols_left: 6,
    rows_right: 4, cols_right: 6,
    vial_compatible: true,
    enabled: true
  },
  "ortho_4x12" => {
    name: "4×12一体型（オーソリニア）",
    name_en: "4×12 Unibody (Ortholinear)",
    grid_type: :ortho,
    rows: 4, cols: 12,
    vial_compatible: true,
    enabled: true
  }
}.freeze
```

### 2. デフォルトキーマップ

YAMLファイルでキーボードタイプごとに管理:

- `config/default_keymaps/split_4x6.yml`
- `config/default_keymaps/ortho_4x12.yml`

**ロード方法:**
```ruby
Keymap.default_keymap_for_type(keyboard_type)
```

### 3. ビューパーシャル

キーボードタイプごとに個別ファイル:

- 編集画面: `app/views/my/keymaps/_keyboard_grid_{type}.html.slim`
- 練習画面: `app/views/lessons/_keyboard_grid_{type}.html.slim`

**レンダリング:**
```slim
= render "keyboard_grid_#{@keyboard_type}"
```

### 4. JavaScript（指マッピング）

[app/javascript/controllers/typing_controller.js](../../app/javascript/controllers/typing_controller.js)

```javascript
fingerPositionMappings = {
  'split_4x6': { /* ... */ },
  'ortho_4x12': { /* ... */ }
}
```

### 5. KeymapSet モデル

```ruby
# keyboard_type: string (split_4x6, ortho_4x12, など)
validates :keyboard_type, presence: true,
  inclusion: { in: KEYBOARD_TYPES.keys }

def keyboard_config
  KEYBOARD_TYPES[keyboard_type]
end
```

---

## 新しいキーボードタイプの追加手順

新タイプの追加コスト: **約1-2時間**

1. `KEYBOARD_TYPES` にエントリ追加
2. デフォルトキーマップ YAML 作成 (`config/default_keymaps/`)
3. ビューパーシャル作成（編集画面・練習画面）
4. JavaScript 指マッピング追加
5. 完成！

---

## 実装済みキーボードタイプ

### split_4x6

4×6分割型（Cornix等）

- **grid_type**: split
- **rows_left/rows_right**: 4
- **cols_left/cols_right**: 6
- **特徴**: 左右分割、オーソリニア配列

### ortho_4x12

4×12一体型（Planck等）

- **grid_type**: ortho
- **rows**: 4
- **cols**: 12
- **特徴**: 一体型、オーソリニア配列（4×6を横に並べた配列）

---

## 5×14 → 4×12 への戦略的ピボット

### 当初計画

5×14一体型を追加

### 問題点

- デフォルトキーマップ設計が複雑（ホームポジション解釈が複数）
- 指配置の議論が必要
- 本来の目的（**切り替えメカニズムの検証**）から逸脱

### 最終判断

4×12一体型を採用

**理由:**
- 4×6分割型を横に並べただけ（シンプル）
- デフォルトキーマップを流用可能
- 指配置も4×6と同じ
- **メカニズムの実証**という本来の目的に集中できる

**結果**: ✅ 成功（拡張メカニズムが正常に動作）

---

## 将来の拡張候補

### 実装しやすいタイプ（優先度: 中）

1. **5×6分割型** (`split_5x6`)
   - 4×6 + 数字行

2. **4×7分割型** (`split_4x7`)
   - 4×6 + 1列

3. **5×7分割型** (`split_5x7`)
   - 5×6 + 1列

### 複雑なタイプ（優先度: 低）

4. **カラムスタッガード配列**
   - 物理的な列ずれ
   - CSS での位置調整が必要

5. **5×14一体型** (`ortho_5x14`)
   - 指配置カスタマイズ機能とセットで実装推奨

---

## 参考: 当初の複雑な設計案（採用せず）

当初は KeyboardType モデルを使った JSONB ベースの設計を予定していました。

### 設計概要

- KeyboardType モデル（layout_data: JSONB）
- JSON スキーマでキー配置情報を管理
- JavaScript で動的にキーボードを描画

### 不採用の理由

- 過剰設計（オーバーエンジニアリング）
- 実装・保守コストが高い
- 現在のシンプル設計で十分な拡張性を確保できる

---

## 関連ドキュメント

- [機能仕様](features.md)
- [指配置カスタマイズ設計](../future/finger_assignment.md)（将来実装）
