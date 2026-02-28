# Vial形式キーマップ連携機能の設計

**作成日**: 2026-01-12
**ステータス**: 設計段階（未実装）

---

## 📋 概要

Vial形式（`.vil`）のキーマップファイルとTypnixのキーマップを相互変換する機能の設計書。

### 目的

- **インポート**: Vialアプリで作成したキーマップをTypnixで使用可能にする
- **エクスポート**: Typnixで設定したキーマップをVial形式でエクスポートする
- **利便性向上**: 既存のVialユーザーがスムーズにTypnixを利用できるようにする

### 参照ファイル

- サンプルファイル: `tmp/sampke_keymap.vil`

---

## 🔍 Vial形式（`.vil`）の分析

### ファイル構造

Vial形式はJSON形式で、以下の主要フィールドを持つ：

```json
{
  "version": 1,
  "uid": 16882930253541522617,
  "layout": [レイヤー0, レイヤー1, レイヤー2, レイヤー3, レイヤー4, レイヤー5],
  "encoder_layout": [[エンコーダー設定]],
  "macro": [マクロ定義],
  "vial_protocol": 6,
  "via_protocol": 9,
  "tap_dance": [タップダンス設定],
  "combo": [コンボキー設定],
  "key_override": [],
  "alt_repeat_key": [],
  "settings": {}
}
```

### レイヤー構造

- **レイヤー数**: 6レイヤー（Typnixと同じ）
- **物理配列**: 各レイヤーは8行×7列の2次元配列（分割キーボード想定）
- **キーコード**: QMK形式（例: `KC_Q`, `KC_SPACE`, `LSFT(KC_2)`, `MO(1)`）

### 特殊な値

| 値 | 意味 |
|----|------|
| `KC_NO` | キー未割り当て |
| `-1` | 物理的に存在しないキー位置 |
| `MO(n)` | Momentary Layer n（レイヤーnに一時切り替え） |
| `LSFT(KC_X)` | 修飾キー組み合わせ（Left Shift + X） |

### レイヤー0のサンプル（左手側）

```json
[
  ["KC_GRAVE", "KC_Q", "KC_W", "KC_E", "KC_R", "KC_T", -1],
  ["KC_TAB", "KC_A", "KC_S", "KC_D", "KC_F", "KC_G", -1],
  ["KC_LSHIFT", "KC_Z", "KC_X", "KC_C", "KC_V", "KC_B", "KC_MUTE"],
  ["KC_LCTRL", "KC_LALT", "KC_LGUI", "MO(1)", "KC_SPACE", "KC_SPACE", -1]
]
```

---

## 🔄 Typnixとの比較

### データ構造の違い

| 項目 | Vial | Typnix |
|------|------|--------|
| **形式** | JSON（`.vil`ファイル） | PostgreSQL（Keymapテーブル） |
| **キーコード** | QMK形式（`KC_Q`, `LSFT(KC_2)`） | 表示文字ベース（`"q"`, `"shift\|@"`） |
| **レイヤー数** | 6レイヤー | 6レイヤー |
| **物理配列** | 8行×7列の2次元配列 | `key_position`（"0-0", "0-1"形式） |
| **レイヤー切替** | `MO(1)`, `TG(2)`など | 未対応（将来実装予定） |
| **マクロ** | 対応 | 未対応 |
| **タップダンス** | 対応 | 未対応 |
| **コンボキー** | 対応 | 未対応 |

### Typnixのデータモデル

```ruby
# Keymapモデル
{
  user_id: Integer,
  keymap_set_id: Integer,
  layer: Integer (0-5),
  key_position: String ("0-0", "0-1", ...),
  character: String ("a", "b", "shift|A", ...)
}
```

---

## 🚧 主な技術的課題

### 1. キーコード変換の複雑さ

**問題点:**
- Vial: QMK形式（`KC_Q`, `LSFT(KC_2)`, `MO(1)`）
- Typnix: 表示文字ベース（`"q"`, `"shift|@"`, レイヤー切り替えは未対応）

**解決策:**
- QMKキーコード → Typnix文字列の変換テーブルを作成
- 逆変換テーブルも用意

```ruby
# 変換テーブル例
QMK_TO_TYPNIX = {
  "KC_Q" => "q",
  "KC_SPACE" => " ",
  "LSFT(KC_2)" => "shift|@",
  "KC_NO" => "",  # 空文字
  "MO(1)" => "layer|1"  # 新機能として実装（将来）
}.freeze

TYPNIX_TO_QMK = QMK_TO_TYPNIX.invert.freeze
```

### 2. 物理レイアウトの違い

**問題点:**
- Vial: 8行×7列の2次元配列（キーボード固有の物理配列）
- Typnix: `key_position`（"0-0", "0-1"形式、36キー想定）

**解決策:**
- キーボードタイプごとにマッピングテーブルを定義

```ruby
# Cornix (36キー) の場合
VIAL_TO_TYPNIX_POSITION = {
  [0, 1] => "0-0",  # レイヤー0、行0、列1 → "0-0"
  [0, 2] => "0-1",  # レイヤー0、行0、列2 → "0-1"
  [0, 3] => "0-2",
  [0, 4] => "0-3",
  [0, 5] => "0-4",
  [0, 6] => "0-5",
  # ... 36キー分のマッピング
}.freeze

TYPNIX_TO_VIAL_POSITION = VIAL_TO_TYPNIX_POSITION.invert.freeze
```

### 3. Typnix未対応の機能

**VialにあるがTypnixにない機能:**
- レイヤー切り替えキー（`MO(1)`, `TG(2)`など）
- マクロ
- タップダンス
- コンボキー
- エンコーダー設定

**対応方針:**
- **Phase 1**: 基本的なキーマップのみ対応（未対応機能は無視または警告）
- **Phase 2**: レイヤー切り替えキーを新規実装（`character: "layer|1"`形式）
- **Phase 3**: マクロやコンボは将来実装

---

## 📦 実装提案

### Phase 1: 最小限の実装（推奨）

**対応範囲:**
1. **Vilインポート**: Vilファイル → Typnixキーマップ（基本キーのみ）
2. **Vilエクスポート**: Typnixキーマップ → Vilファイル（基本キーのみ）

**スコープ外（Phase 1）:**
- レイヤー切り替えキー（警告を表示してスキップ）
- マクロ、タップダンス、コンボキー（無視）
- エンコーダー設定（デフォルト値を使用）

### コンポーネント設計

#### 1. VialImporter サービスオブジェクト

```ruby
# app/services/vial_importer.rb
class VialImporter
  class UnsupportedKeycodeError < StandardError; end

  def initialize(vil_file_path, keymap_set)
    @vil_data = JSON.parse(File.read(vil_file_path))
    @keymap_set = keymap_set
    @warnings = []
  end

  def import!
    ActiveRecord::Base.transaction do
      @vil_data["layout"].each_with_index do |layer_data, layer_index|
        break if layer_index >= 6  # Typnixは6レイヤーまで

        import_layer(layer_data, layer_index)
      end
    end

    { success: true, warnings: @warnings }
  rescue => e
    { success: false, error: e.message, warnings: @warnings }
  end

  private

  def import_layer(layer_data, layer_index)
    layer_data.each_with_index do |row, row_index|
      row.each_with_index do |qmk_code, col_index|
        next if qmk_code == -1 || qmk_code == "KC_NO"

        typnix_position = vial_position_to_typnix(row_index, col_index)
        unless typnix_position
          @warnings << "位置 [#{row_index}, #{col_index}] のキーは対応していません（スキップ）"
          next
        end

        typnix_char = qmk_to_typnix(qmk_code)
        unless typnix_char
          @warnings << "キーコード「#{qmk_code}」は現在未対応です（スキップ）"
          next
        end

        Keymap.find_or_create_by!(
          keymap_set: @keymap_set,
          layer: layer_index,
          key_position: typnix_position
        ).update!(character: typnix_char)
      end
    end
  end

  def qmk_to_typnix(qmk_code)
    VialKeycodeMap::QMK_TO_TYPNIX[qmk_code]
  end

  def vial_position_to_typnix(row, col)
    VialKeycodeMap::VIAL_POSITION_MAP[[row, col]]
  end
end
```

#### 2. VialExporter サービスオブジェクト

```ruby
# app/services/vial_exporter.rb
class VialExporter
  def initialize(keymap_set)
    @keymap_set = keymap_set
  end

  def export_to_file(output_path)
    vil_data = build_vil_structure
    File.write(output_path, JSON.pretty_generate(vil_data))
    { success: true, file_path: output_path }
  rescue => e
    { success: false, error: e.message }
  end

  private

  def build_vil_structure
    {
      version: 1,
      uid: generate_uid,
      layout: (0..5).map { |layer| build_layer(layer) },
      encoder_layout: build_default_encoder_layout,
      macro: Array.new(32) { [] },
      vial_protocol: 6,
      via_protocol: 9,
      tap_dance: Array.new(32) { ["KC_NO", "KC_NO", "KC_NO", "KC_NO", 200] },
      combo: Array.new(32) { ["KC_NO", "KC_NO", "KC_NO", "KC_NO", "KC_NO"] },
      key_override: [],
      alt_repeat_key: [],
      settings: {}
    }
  end

  def build_layer(layer_index)
    keymaps = @keymap_set.keymaps.where(layer: layer_index).index_by(&:key_position)

    # 8行×7列の2次元配列を構築
    (0..7).map do |row|
      (0..6).map do |col|
        typnix_position = VialKeycodeMap::VIAL_POSITION_MAP[[row, col]]

        if typnix_position.nil?
          -1  # 存在しないキー位置
        else
          keymap = keymaps[typnix_position]
          if keymap
            typnix_to_qmk(keymap.character)
          else
            "KC_NO"  # 未割り当て
          end
        end
      end
    end
  end

  def typnix_to_qmk(typnix_char)
    VialKeycodeMap::TYPNIX_TO_QMK[typnix_char] || "KC_NO"
  end

  def generate_uid
    # キーボード固有IDを生成（簡易版）
    Time.now.to_i * 1000 + rand(1000)
  end

  def build_default_encoder_layout
    # デフォルトのエンコーダー設定（音量調整）
    Array.new(6) do
      [["KC_VOLD", "KC_VOLU"], ["KC_WH_U", "KC_WH_D"]]
    end
  end
end
```

#### 3. VialKeycodeMap 定数モジュール

```ruby
# config/initializers/vial_keycode_map.rb
module VialKeycodeMap
  # QMK → Typnix 変換テーブル
  QMK_TO_TYPNIX = {
    # 英字
    "KC_A" => "a", "KC_B" => "b", "KC_C" => "c", "KC_D" => "d",
    "KC_E" => "e", "KC_F" => "f", "KC_G" => "g", "KC_H" => "h",
    "KC_I" => "i", "KC_J" => "j", "KC_K" => "k", "KC_L" => "l",
    "KC_M" => "m", "KC_N" => "n", "KC_O" => "o", "KC_P" => "p",
    "KC_Q" => "q", "KC_R" => "r", "KC_S" => "s", "KC_T" => "t",
    "KC_U" => "u", "KC_V" => "v", "KC_W" => "w", "KC_X" => "x",
    "KC_Y" => "y", "KC_Z" => "z",

    # 数字
    "KC_1" => "1", "KC_2" => "2", "KC_3" => "3", "KC_4" => "4",
    "KC_5" => "5", "KC_6" => "6", "KC_7" => "7", "KC_8" => "8",
    "KC_9" => "9", "KC_0" => "0",

    # 記号（基本）
    "KC_SPACE" => " ",
    "KC_MINUS" => "-",
    "KC_EQUAL" => "=",
    "KC_LBRACKET" => "[",
    "KC_RBRACKET" => "]",
    "KC_BSLASH" => "\\",
    "KC_SCOLON" => ";",
    "KC_QUOTE" => "'",
    "KC_GRAVE" => "`",
    "KC_COMMA" => ",",
    "KC_DOT" => ".",
    "KC_SLASH" => "/",

    # Shift組み合わせ記号
    "LSFT(KC_1)" => "shift|!",
    "LSFT(KC_2)" => "shift|@",
    "LSFT(KC_3)" => "shift|#",
    "LSFT(KC_4)" => "shift|$",
    "LSFT(KC_5)" => "shift|%",
    "LSFT(KC_6)" => "shift|^",
    "LSFT(KC_7)" => "shift|&",
    "LSFT(KC_8)" => "shift|*",
    "LSFT(KC_9)" => "shift|(",
    "LSFT(KC_0)" => "shift|)",
    "LSFT(KC_MINUS)" => "shift|_",
    "LSFT(KC_EQUAL)" => "shift|+",
    "LSFT(KC_LBRACKET)" => "shift|{",
    "LSFT(KC_RBRACKET)" => "shift|}",
    "LSFT(KC_BSLASH)" => "shift||",
    "LSFT(KC_SCOLON)" => "shift|:",
    "LSFT(KC_QUOTE)" => "shift|\"",
    "LSFT(KC_GRAVE)" => "shift|~",
    "LSFT(KC_COMMA)" => "shift|<",
    "LSFT(KC_DOT)" => "shift|>",
    "LSFT(KC_SLASH)" => "shift|?",

    # 特殊キー
    "KC_ENTER" => "enter",
    "KC_ESCAPE" => "escape",
    "KC_BSPACE" => "backspace",
    "KC_TAB" => "tab",
    "KC_DELETE" => "delete",

    # 矢印キー
    "KC_UP" => "up",
    "KC_DOWN" => "down",
    "KC_LEFT" => "left",
    "KC_RIGHT" => "right",

    # 修飾キー（Phase 1では未対応、空文字で警告）
    "KC_LSHIFT" => "",
    "KC_RSHIFT" => "",
    "KC_LCTRL" => "",
    "KC_RCTRL" => "",
    "KC_LALT" => "",
    "KC_RALT" => "",
    "KC_LGUI" => "",
    "KC_RGUI" => "",

    # レイヤー切り替え（Phase 1では未対応）
    # "MO(1)" => "layer|1",  # 将来実装

    # その他
    "KC_NO" => "",
    "KC_MUTE" => "",  # エンコーダーボタン（未対応）
  }.freeze

  # Typnix → QMK 逆変換テーブル
  TYPNIX_TO_QMK = QMK_TO_TYPNIX.invert.freeze

  # Vial物理配列 → Typnix key_position マッピング
  # Cornix (36キー、3x6 + 3 thumb) の場合
  VIAL_POSITION_MAP = {
    # 左手側（行0-3、列1-6）
    [0, 1] => "0-0", [0, 2] => "0-1", [0, 3] => "0-2",
    [0, 4] => "0-3", [0, 5] => "0-4", [0, 6] => "0-5",

    [1, 1] => "1-0", [1, 2] => "1-1", [1, 3] => "1-2",
    [1, 4] => "1-3", [1, 5] => "1-4", [1, 6] => "1-5",

    [2, 1] => "2-0", [2, 2] => "2-1", [2, 3] => "2-2",
    [2, 4] => "2-3", [2, 5] => "2-4", [2, 6] => "2-5",

    [3, 3] => "3-0", [3, 4] => "3-1", [3, 5] => "3-2",

    # 右手側（行4-7、列0-5）
    [4, 0] => "0-6", [4, 1] => "0-7", [4, 2] => "0-8",
    [4, 3] => "0-9", [4, 4] => "0-10", [4, 5] => "0-11",

    [5, 0] => "1-6", [5, 1] => "1-7", [5, 2] => "1-8",
    [5, 3] => "1-9", [5, 4] => "1-10", [5, 5] => "1-11",

    [6, 0] => "2-6", [6, 1] => "2-7", [6, 2] => "2-8",
    [6, 3] => "2-9", [6, 4] => "2-10", [6, 5] => "2-11",

    [7, 0] => "3-3", [7, 1] => "3-4", [7, 2] => "3-5",
  }.freeze

  # Typnix → Vial 逆マッピング
  TYPNIX_TO_VIAL_POSITION = VIAL_POSITION_MAP.invert.freeze
end
```

#### 4. コントローラー追加

```ruby
# app/controllers/my/keymaps_controller.rb に追加
def import_vial
  @keymap_set = current_user.keymap_sets.find_by!(slug: params[:slug])

  if request.post?
    uploaded_file = params[:vil_file]

    if uploaded_file.blank?
      flash[:alert] = "ファイルを選択してください"
      return render :import_vial
    end

    temp_path = Rails.root.join("tmp", "uploaded_#{Time.now.to_i}.vil")
    File.write(temp_path, uploaded_file.read)

    importer = VialImporter.new(temp_path, @keymap_set)
    result = importer.import!

    File.delete(temp_path) if File.exist?(temp_path)

    if result[:success]
      flash[:notice] = "キーマップをインポートしました"
      flash[:warning] = result[:warnings].join("\n") if result[:warnings].any?
      redirect_to edit_my_keymap_path(@keymap_set.slug)
    else
      flash[:alert] = "インポートに失敗しました: #{result[:error]}"
      render :import_vial
    end
  end
end

def export_vial
  @keymap_set = current_user.keymap_sets.find_by!(slug: params[:slug])

  output_path = Rails.root.join("tmp", "#{@keymap_set.slug}_#{Time.now.to_i}.vil")

  exporter = VialExporter.new(@keymap_set)
  result = exporter.export_to_file(output_path)

  if result[:success]
    send_file output_path, filename: "#{@keymap_set.slug}.vil", type: "application/json"
    # ファイル送信後に削除（バックグラウンドジョブで）
  else
    flash[:alert] = "エクスポートに失敗しました: #{result[:error]}"
    redirect_to edit_my_keymap_path(@keymap_set.slug)
  end
end
```

#### 5. ルーティング追加

```ruby
# config/routes.rb
namespace :my do
  resources :keymaps, param: :slug do
    member do
      get :import_vial
      post :import_vial
      get :export_vial
    end
  end
end
```

#### 6. ビュー追加

```slim
/ app/views/my/keymaps/edit.html.slim にボタン追加
.flex.gap-3.mb-6
  = link_to "Vilファイルをインポート", import_vial_my_keymap_path(@keymap_set.slug), class: "px-4 py-2 bg-green-600 dark:bg-green-700 text-white rounded-lg hover:bg-green-700 dark:hover:bg-green-800 transition"
  = link_to "Vilファイルをエクスポート", export_vial_my_keymap_path(@keymap_set.slug), class: "px-4 py-2 bg-purple-600 dark:bg-purple-700 text-white rounded-lg hover:bg-purple-700 dark:hover:bg-purple-800 transition"

/ app/views/my/keymaps/import_vial.html.slim
.max-w-2xl.mx-auto
  h1.text-2xl.font-bold.mb-6 Vilファイルのインポート

  = form_with url: import_vial_my_keymap_path(@keymap_set.slug), method: :post, multipart: true, class: "space-y-6" do |f|
    .space-y-2
      = f.label :vil_file, "Vilファイルを選択", class: "block text-sm font-medium"
      = f.file_field :vil_file, accept: ".vil", class: "w-full"
      p.text-xs.text-gray-500 Vialアプリからエクスポートした.vilファイルを選択してください

    .bg-yellow-50.dark:bg-yellow-900.border.border-yellow-200.dark:border-yellow-700.rounded-lg.p-4
      h3.font-semibold.mb-2 ⚠️ 注意事項
      ul.list-disc.list-inside.text-sm
        li 現在のキーマップは上書きされます
        li レイヤー切り替えキーは未対応です（スキップされます）
        li マクロ、タップダンス、コンボキーは未対応です

    .flex.gap-3
      = f.submit "インポート", class: "px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
      = link_to "キャンセル", edit_my_keymap_path(@keymap_set.slug), class: "px-6 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600 transition"
```

---

## 📊 実装難易度と工数見積もり

| フェーズ | 内容 | 難易度 | 工数見積もり |
|---------|------|--------|------------|
| **Phase 1a** | QMKキーコード変換テーブル作成 | 中 | 2-3時間 |
| **Phase 1b** | VialImporter実装 | 中 | 2-3時間 |
| **Phase 1c** | VialExporter実装 | 中 | 2-3時間 |
| **Phase 1d** | UI追加（インポート/エクスポートボタン、フォーム） | 低 | 1-2時間 |
| **Phase 1e** | テスト・デバッグ | 中 | 2-3時間 |

**Phase 1合計: 9-14時間（1.5-2日）**

---

## 🚀 実装順序（推奨）

### Step 1: 変換テーブル作成（Phase 1a）
- `config/initializers/vial_keycode_map.rb` を作成
- QMK ↔ Typnix 変換テーブルを定義
- Vial物理配列 ↔ Typnix key_position マッピングを定義

### Step 2: インポーター実装（Phase 1b）
- `app/services/vial_importer.rb` を作成
- 基本的なキーのみ対応
- 未対応キーは警告を出してスキップ

### Step 3: エクスポーター実装（Phase 1c）
- `app/services/vial_exporter.rb` を作成
- Typnixキーマップ → Vil形式に変換
- デフォルト値で未対応フィールドを埋める

### Step 4: UI実装（Phase 1d）
- コントローラーアクション追加
- ルーティング追加
- インポート/エクスポートボタン追加
- インポートフォーム作成

### Step 5: テスト・デバッグ（Phase 1e）
- サンプルファイル（`tmp/sampke_keymap.vil`）でテスト
- エラーハンドリングの確認
- 警告メッセージの確認

---

## 🔮 将来の拡張（Phase 2以降）

### Phase 2: レイヤー切り替えキー対応

**必要な変更:**
1. Typnixのデータモデル拡張
   - `character`カラムで`"layer|1"`形式をサポート
   - タイピング練習画面でレイヤー切り替えを処理
2. 変換テーブルに`MO(n)`, `TG(n)`などを追加
3. UIでレイヤー切り替えキーを設定可能にする

### Phase 3: マクロ・タップダンス対応

**必要な変更:**
1. 新規テーブル作成（Macro、TapDance）
2. Vilファイルのマクロ・タップダンス定義をインポート
3. タイピング練習画面でマクロを処理

### Phase 4: 複数キーボードタイプ対応

**必要な変更:**
1. KeymapSetに`keyboard_type`カラム追加
2. キーボードタイプごとのマッピングテーブル作成
3. UI でキーボードタイプを選択可能にする

---

## 📝 備考

### 制約事項（Phase 1）

- **対応キーボード**: Cornix（36キー）のみ
- **対応キー**: 基本的な英字・数字・記号のみ
- **未対応機能**: レイヤー切り替え、マクロ、タップダンス、コンボキー

### テスト方針

1. **単体テスト**: VialImporter、VialExporter のメソッドをテスト
2. **統合テスト**: サンプルファイルを使った実際のインポート/エクスポート
3. **手動テスト**: Vialアプリでエクスポートしたファイルをインポートし、動作確認

### リスク

| リスク | 影響度 | 対策 |
|--------|--------|------|
| QMKキーコードの網羅性不足 | 中 | 警告を表示してスキップ、段階的に追加 |
| 物理配列マッピングのずれ | 高 | サンプルファイルで十分にテスト |
| Vial形式の仕様変更 | 低 | バージョンチェックを実装 |

---

## 🔗 参考リンク

- [Vial公式サイト](https://get.vial.today/)
- [QMK Firmware - Keycodes](https://docs.qmk.fm/#/keycodes)
- [VIA/Vial JSON形式仕様](https://www.caniusevia.com/docs/specification)

---

**最終更新**: 2026-01-12
**次のアクション**: Phase 1aから段階的に実装を開始
