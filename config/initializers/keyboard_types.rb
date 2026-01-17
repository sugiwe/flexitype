# キーボードタイプの定義
# 12行×8列のグリッド（合計96キー）を想定
# 分割型: 0-5行が左手、6-11行が右手
# 一体型: 0-5行を全列使用

KEYBOARD_TYPES = {
  "split_4x6" => {
    name: "4×6分割型（オーソリニア）",
    name_en: "4×6 Split (Ortholinear)",
    grid_type: :split,
    rows_left: 4,   # 左手の行数
    cols_left: 6,   # 左手の列数
    rows_right: 4,  # 右手の行数
    cols_right: 6,  # 右手の列数
    vial_compatible: true,
    enabled: true,  # UI選択可能
    description: "4行×6列の分割型キーボード（格子配列）"
  },
  "split_4x7" => {
    name: "4×7分割型（オーソリニア）",
    name_en: "4×7 Split (Ortholinear)",
    grid_type: :split,
    rows_left: 4,
    cols_left: 7,
    rows_right: 4,
    cols_right: 7,
    vial_compatible: true,
    enabled: false,  # 将来実装
    description: "4行×7列の分割型キーボード（格子配列）"
  },
  "split_5x6" => {
    name: "5×6分割型（オーソリニア）",
    name_en: "5×6 Split (Ortholinear)",
    grid_type: :split,
    rows_left: 5,
    cols_left: 6,
    rows_right: 5,
    cols_right: 6,
    vial_compatible: true,
    enabled: false,  # 将来実装
    description: "5行×6列の分割型キーボード（格子配列・数字行付き等）"
  },
  "split_5x7" => {
    name: "5×7分割型（オーソリニア）",
    name_en: "5×7 Split (Ortholinear)",
    grid_type: :split,
    rows_left: 5,
    cols_left: 7,
    rows_right: 5,
    cols_right: 7,
    vial_compatible: true,
    enabled: false,  # 将来実装
    description: "5行×7列の分割型キーボード（格子配列・数字行付き等）"
  },
  "ortho_4x12" => {
    name: "4×12一体型（オーソリニア）",
    name_en: "4×12 Unibody (Ortholinear)",
    grid_type: :ortho,
    rows: 4,
    cols: 12,
    vial_compatible: true,
    enabled: true,   # UI選択可能
    description: "4行×12列の一体型オーソリニアキーボード（4×6分割型を横に並べた配列）"
  }
}.freeze

# キーボードタイプの選択肢（セレクトボックス用）
# enabledがtrueのもののみ表示
KEYBOARD_TYPE_OPTIONS = KEYBOARD_TYPES.select { |_key, config| config[:enabled] }.map do |key, config|
  [ config[:name], key ]
end.freeze
