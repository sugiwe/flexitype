module ApplicationHelper
  # キーマップの文字を表示用に整形する（2段表示対応）
  # @param char [String] キーマップの文字（例: "q", "Q/q", "!/1", "spc", "bs"）
  # @return [String] 表示用のHTML文字列
  def format_key_display(char)
    # nilまたは空文字の場合
    return content_tag(:div, "-", class: "text-xs") if char.nil? || char.to_s.empty?

    # 文字列に変換
    char_str = char.to_s

    # 特殊キーの表示名マッピング（1段表示）
    special_keys = {
      "spc" => "Spc",
      "space" => "Spc",
      "bs" => "BS",
      "backspace" => "BS",
      "ent" => "Ent",
      "enter" => "Ent",
      "tab" => "Tab",
      "shift" => "Shift",
      "ctrl" => "Ctrl",
      "alt" => "Alt",
      "cmd" => "Cmd",
      "caps" => "Caps",
      "esc" => "Esc",
      "del" => "Del",
      "layer1" => "Lyr1",
      "lyr1" => "Lyr1",
      "layer2" => "Lyr2",
      "lyr2" => "Lyr2",
      "lower" => "Lower",
      "raise" => "Raise"
    }

    # 特殊キーの場合は1段表示
    if special_keys[char_str.downcase]
      return content_tag(:div, special_keys[char_str.downcase], class: "text-xs text-gray-700 dark:text-gray-200")
    end

    # "Q|q" や "!|1" 形式の場合は2段表示
    # 上段: 小さめ・グレー、下段: 大きめ・太字・黒
    if char_str.include?("|")
      parts = char_str.split("|")
      upper = parts[0] || ""
      lower = parts[1] || ""

      return content_tag(:div, class: "flex flex-col items-center justify-center h-full") do
        content_tag(:div, upper, class: "text-xs text-gray-400 dark:text-gray-400 mb-1") +
        content_tag(:div, lower, class: "text-base font-semibold text-gray-700 dark:text-gray-200")
      end
    end

    # 単一文字の場合
    content_tag(:div, char_str, class: "text-xs text-gray-700 dark:text-gray-200")
  end
end
