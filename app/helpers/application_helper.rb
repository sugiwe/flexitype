module ApplicationHelper
  # 管理者かどうかを判定する
  # @return [Boolean] 管理者の場合true
  def admin?
    current_user&.admin?
  end

  # キーマップの文字を表示用に整形する（2段表示対応）
  # @param char [String] キーマップの文字（例: "q", "Q/q", "!/1", "spc", "bs"）
  # @return [String] 表示用のHTML文字列
  def format_key_display(char)
    # nilまたは空文字の場合は空欄（何も表示しない）
    return content_tag(:div, "", class: "text-xs") if char.nil? || char.to_s.empty?

    # 文字列に変換
    char_str = char.to_s

    # blankの場合は✕マーク（背景は親要素で設定）
    if char_str.downcase == "blank"
      return content_tag(:div, "✕", class: "text-base text-gray-300 dark:text-gray-400")
    end

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
      "win" => "Win",
      "menu" => "Menu",
      "caps" => "Caps",
      "esc" => "Esc",
      "del" => "Del",
      "layer1" => "Lyr1",
      "lyr1" => "Lyr1",
      "layer2" => "Lyr2",
      "lyr2" => "Lyr2",
      "layer3" => "Lyr3",
      "lyr3" => "Lyr3",
      "layer4" => "Lyr4",
      "lyr4" => "Lyr4",
      "layer5" => "Lyr5",
      "lyr5" => "Lyr5",
      "lower" => "Lower",
      "raise" => "Raise",
      "fn" => "Fn",
      "f1" => "F1",
      "f2" => "F2",
      "f3" => "F3",
      "f4" => "F4",
      "f5" => "F5",
      "f6" => "F6",
      "f7" => "F7",
      "f8" => "F8",
      "f9" => "F9",
      "f10" => "F10",
      "f11" => "F11",
      "f12" => "F12"
    }

    # 特殊キーの場合は1段表示
    if special_keys[char_str.downcase]
      return content_tag(:div, special_keys[char_str.downcase], class: "text-xs text-gray-700 dark:text-gray-200")
    end

    # "Q q" や "! 1" 形式（半角スペース区切り）の場合は2段表示
    # 上段: 小さめ・グレー、下段: 大きめ・太字・黒
    if char_str.include?(" ")
      parts = char_str.split(" ")
      upper = parts[0] || ""
      lower = parts[1] || ""

      return content_tag(:div, class: "flex flex-col items-center justify-center h-full") do
        content_tag(:div, upper, class: "text-xs text-gray-400 dark:text-gray-400 mb-1") +
        content_tag(:div, lower, class: "text-base font-semibold text-gray-700 dark:text-gray-200")
      end
    # 【後方互換性】"Q|q" や "!|1" 形式（|区切り）もサポート（既存データ用）
    # 注意: 新規保存時は半角スペース区切りを使用すること
    # 単体の「|」文字との衝突を避けるため、2文字以上かつ「|」を含む場合のみ適用
    elsif char_str.include?("|") && char_str.length > 1
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
