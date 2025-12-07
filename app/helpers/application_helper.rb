module ApplicationHelper
  # キーマップの文字を表示用に整形する
  # @param char [String] キーマップの文字（例: "q", "Q/q", "spc", "bs"）
  # @return [String] 表示用の文字列
  def format_key_display(char)
    # nilまたは空文字の場合
    return "-" if char.nil? || char.to_s.empty?

    # 文字列に変換
    char_str = char.to_s

    # "Q/q" 形式の場合は大文字側を取得
    if char_str.include?("/")
      parts = char_str.split("/")
      return parts[0].to_s.upcase if parts[0].present?
    end

    # 特殊キーの表示名マッピング
    special_keys = {
      "spc" => "Spc",
      "bs" => "BS",
      "ent" => "Ent",
      "tab" => "Tab",
      "shift" => "Shift",
      "ctrl" => "Ctrl",
      "alt" => "Alt",
      "cmd" => "Cmd",
      "caps" => "Caps",
      "esc" => "Esc",
      "del" => "Del",
      "layer1" => "Lyr1",
      "layer2" => "Lyr2",
      "lower" => "Lower",
      "raise" => "Raise"
    }

    # 特殊キーの場合は表示名を返す、それ以外は大文字化
    special_keys[char_str.downcase] || char_str.upcase
  end
end
