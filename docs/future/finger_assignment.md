# 指アサインメントのカスタマイズ機能実装ガイド

**作成日**: 2026-01-12
**ステータス**: 将来実装予定
**優先度**: 中（ユーザーフィードバック次第で上昇）

---

## 📋 目次

1. [背景と目的](#背景と目的)
2. [現在の実装概要](#現在の実装概要)
3. [カスタマイズが必要な理由](#カスタマイズが必要な理由)
4. [実装オプションの比較](#実装オプションの比較)
5. [Option 3 実装ステップ（推奨）](#option-3-実装ステップ推奨)
6. [DBスキーマ設計](#dbスキーマ設計)
7. [モデル実装](#モデル実装)
8. [コントローラー実装](#コントローラー実装)
9. [ビュー/UI設計](#ビューui設計)
10. [JavaScript実装](#javascript実装)
11. [マイグレーション戦略](#マイグレーション戦略)
12. [UI/UXの考慮点](#uiuxの考慮点)
13. [テスト戦略](#テスト戦略)
14. [実装時間の見積もり](#実装時間の見積もり)

---

## 背景と目的

### 現在の課題

- タイピング練習画面で「どの指でどのキーを押すべきか」を示す色ガイドがあるが、これは**ハードコードされた固定値**
- ユーザーによって以下の違いがあり、デフォルト設定が最適でない場合がある:
  - タイピングスタイル（ホームポジションの解釈）
  - 手の大きさ・指の長さ
  - キーボードレイアウトの違い（カラムスタッガード vs オーソリニア）
  - 物理的な制約（怪我、障害など）

### 実装の目標

- ユーザーが**キーごとに「どの指で押すべきか」をカスタマイズ**できるようにする
- デフォルト設定を保ちつつ、必要に応じて個別にカスタマイズ可能
- DB に永続化し、ログインすればどのデバイスでも同じ設定を利用可能

---

## 現在の実装概要

### 実装場所

`app/javascript/controllers/typing_controller.js` (lines 5-52)

### コード構造

```javascript
// 指ごとのキー位置マッピング（キーボードタイプ別）
fingerPositionMappings = {
  'split_4x6': {
    'left-pinky': ['0-0', '0-1', '1-0', '1-1', '2-0', '2-1', '3-0', '3-1'],
    'left-ring': ['0-2', '1-2', '2-2', '3-2'],
    'left-middle': ['0-3', '1-3', '2-3'],
    'left-index': ['0-4', '0-5', '1-4', '1-5', '2-4', '2-5'],
    'left-thumb': ['3-3', '3-4', '3-5'],
    'right-thumb': ['9-0', '9-1', '9-2'],
    'right-index': ['6-0', '6-1', '7-0', '7-1', '8-0', '8-1'],
    'right-middle': ['6-2', '7-2', '8-2'],
    'right-ring': ['6-3', '7-3', '8-3'],
    'right-pinky': ['6-4', '6-5', '7-4', '7-5', '8-4', '8-5', '9-3', '9-4', '9-5']
  },
  'ortho_5x14': {
    'left-pinky': ['0-0', '0-1', '1-0', '1-1', '2-0', '2-1', '3-0', '3-1', '4-0', '4-1'],
    'left-ring': ['0-2', '1-2', '2-2', '3-2', '4-2'],
    'left-middle': ['0-3', '1-3', '2-3', '3-3', '4-3'],
    'left-index': ['0-4', '0-5', '1-4', '1-5', '2-4', '2-5', '3-4', '3-5', '4-4', '4-5'],
    'left-thumb': [],  // 一体型キーボードでは親指キーなし
    'right-thumb': [],
    'right-index': ['0-6', '0-7', '1-6', '1-7', '2-6', '2-7', '3-6', '3-7', '4-6', '4-7'],
    'right-middle': ['0-8', '1-8', '2-8', '3-8', '4-8'],
    'right-ring': ['0-9', '1-9', '2-9', '3-9', '4-9'],
    'right-pinky': ['0-10', '0-11', '0-12', '0-13', '1-10', '1-11', '1-12', '1-13', '2-10', '2-11', '2-12', '2-13', '3-10', '3-11', '3-12', '3-13', '4-10', '4-11', '4-12', '4-13']
  }
}

// 現在のキーボードタイプに応じた指マッピングを取得
get fingerPositionMapping() {
  const keyboardType = this.keyboardTypeValue || 'split_4x6'
  return this.fingerPositionMappings[keyboardType] || this.fingerPositionMappings['split_4x6']
}
```

### 問題点

- **ハードコード**: JavaScript ファイルに直接書き込まれており、変更にはコード修正が必要
- **ユーザーカスタマイズ不可**: 全ユーザーが同じマッピングを使用
- **キーボードタイプ依存**: 新しいキーボードタイプを追加するたびにコード修正が必要

---

## カスタマイズが必要な理由

### 1. タイピングスタイルの違い

- **ホームポジション解釈**: 一部のユーザーは小指の担当列を変えたいかもしれない
- **人差し指の範囲**: 人差し指で 2 列押す人もいれば、3 列押す人もいる

### 2. 手の大きさ・指の長さ

- 手が小さい人は小指の範囲を狭くしたい
- 手が大きい人は人差し指の範囲を広げたい

### 3. キーボードレイアウトの違い

- カラムスタッガード配列とオーソリニア配列で最適な指アサインメントが異なる
- キーボードタイプごとにデフォルトを用意しても、微調整が必要

### 4. 物理的な制約

- 怪我や障害により、特定の指が使いづらい場合
- 例: 薬指が使いづらい場合、その列を人差し指や中指に割り当てたい

---

## 実装オプションの比較

### Option 1: 現状維持（デフォルトのみ）

**概要**: 現在のハードコードされたマッピングをそのまま使用

**メリット**:
- 実装コスト: ゼロ
- 複雑性: 低い

**デメリット**:
- ユーザーの多様なニーズに対応できない
- キーボードタイプごとに最適なマッピングを用意する必要がある

**推奨度**: ⭐️⭐️（短期的には問題ないが、長期的には不十分）

---

### Option 2: プリセット選択式（LocalStorage）

**概要**: 複数のプリセット（例: 標準、ワイド、ナロー）を用意し、ユーザーが選択

**メリット**:
- 実装コスト: 低い（1-2 時間）
- DB 変更不要（LocalStorage で保存）
- 複雑性: 低い

**デメリット**:
- 柔軟性が低い（プリセット以外は選べない）
- デバイス間で同期できない（LocalStorage はブラウザローカル）

**推奨度**: ⭐️⭐️⭐️（手軽に実装できるが、柔軟性が低い）

**実装例**:
```javascript
fingerPositionPresets = {
  'split_4x6': {
    'standard': { /* 現在のマッピング */ },
    'wide': { /* 小指の範囲を広げたマッピング */ },
    'narrow': { /* 小指の範囲を狭めたマッピング */ }
  }
}
```

---

### Option 3: 完全カスタマイズ（DB 保存）✅ **推奨**

**概要**: ユーザーがキーごとに指を割り当て、DB に保存

**メリット**:
- 柔軟性が最も高い（ユーザーが完全にカスタマイズ可能）
- デバイス間で同期（ログインすればどこでも同じ設定）
- 将来的に他のユーザーとシェアすることも可能

**デメリット**:
- 実装コスト: 高い（1 日以上）
- DB スキーマ変更、モデル・コントローラー・ビュー・JavaScript すべてに変更が必要
- UI/UX 設計が必要（どうやってユーザーに指を割り当てさせるか）

**推奨度**: ⭐️⭐️⭐️⭐️⭐️（長期的に最も柔軟で拡張性が高い）

---

## Option 3 実装ステップ（推奨）

### Phase 1: DB スキーマ設計とモデル作成

**目的**: 指アサインメントデータを保存するテーブルを作成

**タスク**:
1. `finger_assignments` テーブルの作成
2. `FingerAssignment` モデルの作成
3. `KeymapSet` との関連付け

**所要時間**: 1-2 時間

---

### Phase 2: デフォルト指アサインメントの移行

**目的**: 現在のハードコードされたマッピングを DB に移行

**タスク**:
1. デフォルト指アサインメントを YAML ファイルで定義
2. シードデータとして DB に登録
3. 既存ユーザーに対するデフォルト値の自動生成

**所要時間**: 1-2 時間

---

### Phase 3: コントローラーと API 実装

**目的**: 指アサインメントの CRUD 操作を実装

**タスク**:
1. `My::FingerAssignmentsController` の作成
2. ルーティング設定
3. Strong Parameters 設定

**所要時間**: 1-2 時間

---

### Phase 4: ビュー/UI 実装

**目的**: ユーザーが指アサインメントを編集できる画面を作成

**タスク**:
1. キーボードグリッドの表示
2. 指選択 UI（ドロップダウンまたはカラーピッカー）
3. デフォルトにリセットボタン
4. プレビュー機能（変更を保存する前に確認）

**所要時間**: 3-4 時間

---

### Phase 5: JavaScript 実装

**目的**: DB から読み込んだ指アサインメントを JavaScript で使用

**タスク**:
1. `typing_controller.js` の修正（ハードコードから DB 読み込みへ）
2. JSON 形式で指アサインメントを渡す
3. 動的なハイライト処理

**所要時間**: 2-3 時間

---

### Phase 6: テストとデバッグ

**目的**: 機能が正しく動作することを確認

**タスク**:
1. モデルテスト（バリデーション、関連付け）
2. システムテスト（指アサインメント編集フロー）
3. エッジケースのテスト（未設定キー、無効なデータ）

**所要時間**: 2-3 時間

---

### Phase 7: ドキュメント作成

**目的**: ユーザー向けガイドと開発者向けドキュメントを作成

**タスク**:
1. ヘルプページに指アサインメント設定方法を追加
2. `CLAUDE_FEATURES.md` に機能説明を追加

**所要時間**: 1 時間

---

## DBスキーマ設計

### `finger_assignments` テーブル

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_finger_assignments.rb
class CreateFingerAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :finger_assignments do |t|
      t.references :keymap_set, null: false, foreign_key: true, index: true
      t.string :key_position, null: false  # "0-0", "0-1", etc.
      t.string :finger, null: false         # "left-pinky", "left-ring", etc.

      t.timestamps

      # 複合ユニーク制約（同じキーマップセット内で同じキー位置は1つだけ）
      t.index [:keymap_set_id, :key_position], unique: true
    end
  end
end
```

### カラム説明

| カラム名        | 型         | 制約      | 説明                                |
|-----------------|------------|-----------|-------------------------------------|
| `keymap_set_id` | `bigint`   | NOT NULL  | KeymapSet への外部キー              |
| `key_position`  | `string`   | NOT NULL  | キー位置（例: "0-0", "4-13"）       |
| `finger`        | `string`   | NOT NULL  | 指の名前（例: "left-pinky"）        |
| `created_at`    | `datetime` | NOT NULL  | 作成日時                            |
| `updated_at`    | `datetime` | NOT NULL  | 更新日時                            |

### インデックス戦略

1. **`keymap_set_id` に単独インデックス**: 特定のキーマップセットの全指アサインメントを取得するときに使用
2. **`(keymap_set_id, key_position)` に複合ユニークインデックス**:
   - 同じキーマップセット内で同じキー位置に複数の指が割り当てられるのを防ぐ
   - 高速な検索を保証

---

## モデル実装

### `FingerAssignment` モデル

```ruby
# app/models/finger_assignment.rb
class FingerAssignment < ApplicationRecord
  belongs_to :keymap_set

  # バリデーション
  validates :key_position, presence: true, format: {
    with: /\A([0-9]|1[0-1])-([0-9]|1[0-3])\z/,
    message: "must be in format 'row-col' where row is 0-11 and col is 0-13"
  }
  validates :finger, presence: true, inclusion: {
    in: %w[
      left-pinky left-ring left-middle left-index left-thumb
      right-thumb right-index right-middle right-ring right-pinky
    ],
    message: "must be a valid finger name"
  }
  validates :key_position, uniqueness: { scope: :keymap_set_id }

  # スコープ
  scope :for_keymap_set, ->(keymap_set_id) { where(keymap_set_id: keymap_set_id) }

  # 指アサインメントをハッシュ形式で取得
  # @param keymap_set_id [Integer] キーマップセットID
  # @return [Hash] キー位置 => 指の名前
  def self.mapping_for_keymap_set(keymap_set_id)
    for_keymap_set(keymap_set_id)
      .pluck(:key_position, :finger)
      .to_h
  end

  # デフォルト指アサインメントを作成
  # @param keymap_set [KeymapSet] キーマップセット
  def self.create_defaults_for(keymap_set)
    default_mapping = default_mapping_for_keyboard_type(keymap_set.keyboard_type)

    default_mapping.each do |finger, positions|
      positions.each do |position|
        create!(
          keymap_set: keymap_set,
          key_position: position,
          finger: finger
        )
      end
    end
  end

  # キーボードタイプごとのデフォルトマッピング
  # @param keyboard_type [String] キーボードタイプ
  # @return [Hash] 指 => [キー位置の配列]
  def self.default_mapping_for_keyboard_type(keyboard_type)
    @default_mappings ||= {}
    @default_mappings[keyboard_type] ||= begin
      yaml_path = Rails.root.join("config", "finger_assignments", "#{keyboard_type}.yml")

      unless File.exist?(yaml_path)
        yaml_path = Rails.root.join("config", "finger_assignments", "split_4x6.yml")
      end

      YAML.load_file(yaml_path)
    end
  end
end
```

### `KeymapSet` モデルへの追加

```ruby
# app/models/keymap_set.rb
class KeymapSet < ApplicationRecord
  # ... existing code ...

  has_many :finger_assignments, dependent: :destroy

  # キーマップセット作成後にデフォルト指アサインメントを作成
  after_create :create_default_finger_assignments

  private

  def create_default_finger_assignments
    FingerAssignment.create_defaults_for(self)
  end
end
```

---

## コントローラー実装

### `My::FingerAssignmentsController`

```ruby
# app/controllers/my/finger_assignments_controller.rb
class My::FingerAssignmentsController < ApplicationController
  before_action :require_login
  before_action :set_keymap_set
  before_action :authorize_keymap_set

  # GET /my/keymaps/:keymap_set_slug/finger_assignments/edit
  def edit
    @finger_assignments = @keymap_set.finger_assignments.order(:key_position)
    @keyboard_config = KEYBOARD_TYPES[@keymap_set.keyboard_type]
  end

  # PATCH/PUT /my/keymaps/:keymap_set_slug/finger_assignments
  def update
    if update_finger_assignments(finger_assignment_params)
      redirect_to edit_my_keymap_finger_assignments_path(@keymap_set.slug),
                  notice: t('finger_assignments.update.success')
    else
      @finger_assignments = @keymap_set.finger_assignments.order(:key_position)
      @keyboard_config = KEYBOARD_TYPES[@keymap_set.keyboard_type]
      render :edit, status: :unprocessable_entity
    end
  end

  # POST /my/keymaps/:keymap_set_slug/finger_assignments/reset
  def reset
    @keymap_set.finger_assignments.destroy_all
    FingerAssignment.create_defaults_for(@keymap_set)

    redirect_to edit_my_keymap_finger_assignments_path(@keymap_set.slug),
                notice: t('finger_assignments.reset.success')
  end

  private

  def set_keymap_set
    @keymap_set = KeymapSet.find_by!(slug: params[:keymap_set_slug])
  end

  def authorize_keymap_set
    unless @keymap_set.user_id == current_user.id
      redirect_to root_path, alert: t('errors.unauthorized')
    end
  end

  def finger_assignment_params
    params.require(:finger_assignments).permit!
  end

  def update_finger_assignments(assignments)
    ActiveRecord::Base.transaction do
      assignments.each do |key_position, finger|
        next if finger.blank?

        assignment = @keymap_set.finger_assignments.find_or_initialize_by(
          key_position: key_position
        )
        assignment.finger = finger
        assignment.save!
      end
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
end
```

### ルーティング

```ruby
# config/routes.rb
namespace :my do
  resources :keymaps, param: :slug, only: [:index, :new, :create, :edit, :update, :destroy] do
    # 指アサインメント設定
    resource :finger_assignments, only: [:edit, :update] do
      post :reset, on: :collection
    end
  end
end
```

---

## ビュー/UI設計

### `edit.html.slim`

```slim
/ app/views/my/finger_assignments/edit.html.slim
.container.mx-auto.px-4.py-8
  h1.text-3xl.font-bold.mb-6 = t('finger_assignments.edit.title', keymap_name: @keymap_set.name)

  p.text-sm.text-gray-600.dark:text-gray-400.mb-8
    = t('finger_assignments.edit.description')

  / キーボードグリッド + 指選択UI
  = form_with url: my_keymap_finger_assignments_path(@keymap_set.slug), method: :patch, data: { controller: "finger-assignment-editor" } do |f|

    / キーボードグリッド表示
    .mb-8
      = render "finger_assignment_grid", keymap_set: @keymap_set, finger_assignments: @finger_assignments

    / 指選択凡例
    .mb-8
      h3.text-lg.font-semibold.mb-4 = t('finger_assignments.edit.legend')
      .grid.grid-cols-2.md:grid-cols-5.gap-3
        - FingerAssignment::FINGER_NAMES.each do |finger|
          .flex.items-center.gap-2
            .w-8.h-8.rounded class=finger_color_class(finger)
            span.text-sm = t("finger_assignments.fingers.#{finger}")

    / アクションボタン
    .flex.justify-between.items-center
      .flex.gap-3
        = f.submit t('finger_assignments.edit.save'), class: "px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
        = link_to t('finger_assignments.edit.cancel'), my_keymaps_path, class: "px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"

      = button_to t('finger_assignments.edit.reset'),
                  reset_my_keymap_finger_assignments_path(@keymap_set.slug),
                  method: :post,
                  class: "px-6 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700",
                  data: { confirm: t('finger_assignments.edit.reset_confirm') }
```

### `_finger_assignment_grid.html.slim`

```slim
/ app/views/my/finger_assignments/_finger_assignment_grid.html.slim
/ キーボードタイプに応じた動的グリッド
= render "finger_assignment_grid_#{keymap_set.keyboard_type}",
         keymap_set: keymap_set,
         finger_assignments: finger_assignments
```

### `_finger_assignment_grid_split_4x6.html.slim`

```slim
/ app/views/my/finger_assignments/_finger_assignment_grid_split_4x6.html.slim
.flex.justify-center.gap-12
  / 左手側
  .keyboard-half
    .grid.gap-1.5.keyboard-grid-6col
      - (0..3).each do |row|
        - (0..5).each do |col|
          - position = "#{row}-#{col}"
          - assignment = finger_assignments.find { |fa| fa.key_position == position }
          - current_finger = assignment&.finger || "left-pinky"

          .key.relative class=finger_color_class(current_finger) data-position=position
            / キー位置表示
            .text-xs.text-gray-500 = position

            / 指選択ドロップダウン
            select.absolute.inset-0.opacity-0.cursor-pointer name="finger_assignments[#{position}]" data-action="change->finger-assignment-editor#updateColor"
              - FingerAssignment::LEFT_FINGERS.each do |finger|
                option value=finger selected=(current_finger == finger) = t("finger_assignments.fingers.#{finger}")

  / 右手側（同様の構造）
  / ...
```

### UI/UX のポイント

1. **ドロップダウン方式**: 各キーに透明なドロップダウンを重ね、選択すると色が変わる
2. **色による視覚的フィードバック**: 指ごとに色分け（現在の練習画面と同じ色）
3. **リセット機能**: デフォルトに戻すボタン
4. **プレビュー**: 変更内容を保存前に確認できる

---

## JavaScript実装

### `typing_controller.js` の修正

```javascript
// app/javascript/controllers/typing_controller.js
export default class extends Controller {
  static values = {
    // ... existing values
    fingerAssignments: Object  // 追加: DB から読み込んだ指アサインメント
  }

  // ハードコードされたマッピングを削除
  // fingerPositionMappings = { ... }  // 削除

  // DB から読み込んだマッピングを使用
  get fingerPositionMapping() {
    if (this.hasFingerAssignmentsValue && Object.keys(this.fingerAssignmentsValue).length > 0) {
      // DB から読み込んだカスタムマッピングを使用
      return this.convertToFingerMapping(this.fingerAssignmentsValue)
    } else {
      // フォールバック: デフォルトマッピング
      console.warn("No custom finger assignments found, using default")
      return this.getDefaultFingerMapping()
    }
  }

  // キー位置 => 指 のマッピングを、指 => [キー位置] に変換
  convertToFingerMapping(assignments) {
    const mapping = {}

    Object.entries(assignments).forEach(([position, finger]) => {
      if (!mapping[finger]) {
        mapping[finger] = []
      }
      mapping[finger].push(position)
    })

    return mapping
  }

  // デフォルトマッピング（フォールバック用）
  getDefaultFingerMapping() {
    // 現在のハードコードされたマッピングをここに移動
    // ...
  }
}
```

### コントローラーから JavaScript へのデータ渡し

```slim
/ app/views/lessons/show.html.slim (line 21)
.bg-white.dark:bg-gray-800... data-controller="typing"
                             data-typing-finger-assignments-value=@finger_assignments.to_json
```

```ruby
# app/controllers/lessons_controller.rb
def show
  # ... existing code ...

  # 指アサインメントを取得（ユーザーのアクティブなキーマップセットから）
  if user_id && current_user.active_keymap_set
    @finger_assignments = FingerAssignment.mapping_for_keymap_set(
      current_user.active_keymap_set.id
    )
  else
    @finger_assignments = {}  # デフォルトを JavaScript 側で使用
  end
end
```

---

## マイグレーション戦略

### 既存ユーザーへのデフォルト値の適用

```ruby
# db/migrate/YYYYMMDDHHMMSS_populate_finger_assignments_for_existing_keymap_sets.rb
class PopulateFingerAssignmentsForExistingKeymapSets < ActiveRecord::Migration[8.1]
  def up
    KeymapSet.find_each do |keymap_set|
      # すでに指アサインメントが存在する場合はスキップ
      next if keymap_set.finger_assignments.exists?

      # デフォルト指アサインメントを作成
      FingerAssignment.create_defaults_for(keymap_set)
    end
  end

  def down
    # ロールバック時は何もしない（手動で削除する場合のみ）
  end
end
```

### デフォルト指アサインメントの YAML 定義

```yaml
# config/finger_assignments/split_4x6.yml
left-pinky:
  - "0-0"
  - "0-1"
  - "1-0"
  - "1-1"
  - "2-0"
  - "2-1"
  - "3-0"
  - "3-1"

left-ring:
  - "0-2"
  - "1-2"
  - "2-2"
  - "3-2"

left-middle:
  - "0-3"
  - "1-3"
  - "2-3"

left-index:
  - "0-4"
  - "0-5"
  - "1-4"
  - "1-5"
  - "2-4"
  - "2-5"

left-thumb:
  - "3-3"
  - "3-4"
  - "3-5"

right-thumb:
  - "9-0"
  - "9-1"
  - "9-2"

right-index:
  - "6-0"
  - "6-1"
  - "7-0"
  - "7-1"
  - "8-0"
  - "8-1"

right-middle:
  - "6-2"
  - "7-2"
  - "8-2"

right-ring:
  - "6-3"
  - "7-3"
  - "8-3"

right-pinky:
  - "6-4"
  - "6-5"
  - "7-4"
  - "7-5"
  - "8-4"
  - "8-5"
  - "9-3"
  - "9-4"
  - "9-5"
```

```yaml
# config/finger_assignments/ortho_5x14.yml
left-pinky:
  - "0-0"
  - "0-1"
  - "1-0"
  - "1-1"
  - "2-0"
  - "2-1"
  - "3-0"
  - "3-1"
  - "4-0"
  - "4-1"

left-ring:
  - "0-2"
  - "1-2"
  - "2-2"
  - "3-2"
  - "4-2"

left-middle:
  - "0-3"
  - "1-3"
  - "2-3"
  - "3-3"
  - "4-3"

left-index:
  - "0-4"
  - "0-5"
  - "1-4"
  - "1-5"
  - "2-4"
  - "2-5"
  - "3-4"
  - "3-5"
  - "4-4"
  - "4-5"

left-thumb: []

right-thumb: []

right-index:
  - "0-6"
  - "0-7"
  - "1-6"
  - "1-7"
  - "2-6"
  - "2-7"
  - "3-6"
  - "3-7"
  - "4-6"
  - "4-7"

right-middle:
  - "0-8"
  - "1-8"
  - "2-8"
  - "3-8"
  - "4-8"

right-ring:
  - "0-9"
  - "1-9"
  - "2-9"
  - "3-9"
  - "4-9"

right-pinky:
  - "0-10"
  - "0-11"
  - "0-12"
  - "0-13"
  - "1-10"
  - "1-11"
  - "1-12"
  - "1-13"
  - "2-10"
  - "2-11"
  - "2-12"
  - "2-13"
  - "3-10"
  - "3-11"
  - "3-12"
  - "3-13"
  - "4-10"
  - "4-11"
  - "4-12"
  - "4-13"
```

---

## UI/UXの考慮点

### 1. 初回設定のオンボーディング

- キーマップセット作成時に「指アサインメントをカスタマイズしますか?」と尋ねる
- デフォルトで良い場合はスキップ可能

### 2. 視覚的なフィードバック

- 指ごとに色分け（現在の練習画面と同じ色）
- ホバー時に指の名前を表示
- 変更した箇所を強調表示（例: 青い枠線）

### 3. プレビュー機能

- 保存前に練習画面でどう見えるかプレビュー
- モーダルで練習画面のミニチュアを表示

### 4. エラーハンドリング

- 未設定のキーがある場合は警告表示
- 無効な指の名前を選択した場合はバリデーションエラー

### 5. モバイル対応

- ドロップダウンの代わりにボトムシートで指を選択
- タップでキーを選択、スワイプで指を割り当て

---

## テスト戦略

### モデルテスト

```ruby
# spec/models/finger_assignment_spec.rb
RSpec.describe FingerAssignment, type: :model do
  describe "associations" do
    it { should belong_to(:keymap_set) }
  end

  describe "validations" do
    it { should validate_presence_of(:key_position) }
    it { should validate_presence_of(:finger) }

    it "validates key_position format" do
      assignment = build(:finger_assignment, key_position: "invalid")
      expect(assignment).not_to be_valid
      expect(assignment.errors[:key_position]).to be_present
    end

    it "validates finger inclusion" do
      assignment = build(:finger_assignment, finger: "invalid-finger")
      expect(assignment).not_to be_valid
      expect(assignment.errors[:finger]).to be_present
    end

    it "validates uniqueness of key_position within keymap_set" do
      existing = create(:finger_assignment, key_position: "0-0")
      duplicate = build(:finger_assignment,
                        keymap_set: existing.keymap_set,
                        key_position: "0-0")
      expect(duplicate).not_to be_valid
    end
  end

  describe ".mapping_for_keymap_set" do
    it "returns hash of key_position => finger" do
      keymap_set = create(:keymap_set)
      create(:finger_assignment, keymap_set: keymap_set, key_position: "0-0", finger: "left-pinky")
      create(:finger_assignment, keymap_set: keymap_set, key_position: "0-1", finger: "left-ring")

      mapping = FingerAssignment.mapping_for_keymap_set(keymap_set.id)
      expect(mapping).to eq({
        "0-0" => "left-pinky",
        "0-1" => "left-ring"
      })
    end
  end

  describe ".create_defaults_for" do
    it "creates default finger assignments for keymap_set" do
      keymap_set = create(:keymap_set, keyboard_type: "split_4x6")

      expect {
        FingerAssignment.create_defaults_for(keymap_set)
      }.to change { keymap_set.finger_assignments.count }.from(0).to be > 0
    end
  end
end
```

### システムテスト

```ruby
# spec/system/finger_assignments_spec.rb
RSpec.describe "Finger Assignments", type: :system do
  let(:user) { create(:user) }
  let(:keymap_set) { create(:keymap_set, user: user) }

  before do
    sign_in user
  end

  describe "editing finger assignments" do
    it "allows user to change finger assignment for a key" do
      visit edit_my_keymap_finger_assignments_path(keymap_set.slug)

      # キー "0-0" の指を変更
      select "left-ring", from: "finger_assignments[0-0]"
      click_button I18n.t('finger_assignments.edit.save')

      expect(page).to have_content I18n.t('finger_assignments.update.success')
      expect(keymap_set.finger_assignments.find_by(key_position: "0-0").finger).to eq "left-ring"
    end

    it "allows user to reset to default finger assignments" do
      # カスタマイズ後にリセット
      keymap_set.finger_assignments.first.update!(finger: "left-ring")

      visit edit_my_keymap_finger_assignments_path(keymap_set.slug)
      click_button I18n.t('finger_assignments.edit.reset')

      expect(page).to have_content I18n.t('finger_assignments.reset.success')
      # デフォルト値に戻っていることを確認
    end
  end
end
```

---

## 実装時間の見積もり

| Phase | タスク | 所要時間 |
|-------|--------|----------|
| Phase 1 | DB スキーマ設計とモデル作成 | 1-2 時間 |
| Phase 2 | デフォルト指アサインメントの移行 | 1-2 時間 |
| Phase 3 | コントローラーと API 実装 | 1-2 時間 |
| Phase 4 | ビュー/UI 実装 | 3-4 時間 |
| Phase 5 | JavaScript 実装 | 2-3 時間 |
| Phase 6 | テストとデバッグ | 2-3 時間 |
| Phase 7 | ドキュメント作成 | 1 時間 |
| **合計** | | **11-17 時間（約 1.5-2 日）** |

---

## まとめ

### 実装の優先度

1. **短期（今すぐ）**: Option 1（現状維持）
2. **中期（1-2 ヶ月後）**: Option 2（プリセット選択）
3. **長期（3-6 ヶ月後）**: Option 3（完全カスタマイズ）

### 推奨アプローチ

1. まずは Option 1 で運用し、ユーザーフィードバックを収集
2. 「指の割り当てを変えたい」という要望が多ければ Option 2 を実装
3. さらに柔軟性が求められる場合、Option 3 を実装

### 技術的な利点

- **拡張性**: 新しいキーボードタイプを追加しても、デフォルト YAML を追加するだけ
- **保守性**: ハードコードを削除し、DB で管理することでコードがシンプルに
- **ユーザー体験**: ユーザーが自分好みにカスタマイズでき、満足度が向上

---

**作成者**: Claude Code
**最終更新**: 2026-01-12
