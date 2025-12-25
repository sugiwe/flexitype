# frozen_string_literal: true

# タイピング練習のグレード定義
# LessonRecordモデルで使用される5段階のカワウソグレード
module LessonGrades
  DEFINITIONS = {
    "legendary" => {
      name: "伝説のカワウソ",
      emoji: "👑",
      image: "grade_5_legendary.png",
      description: "タイピングの神様！",
      color: "yellow",
      accuracy_min: 98,
      wpm_min: 80
    },
    "adult" => {
      name: "熟練のカワウソ",
      emoji: "🦦",
      image: "grade_4_adult.png",
      description: "堂々としたタイピング",
      color: "blue",
      accuracy_min: 90,
      wpm_min: 50
    },
    "young" => {
      name: "若手のカワウソ",
      emoji: "🐾",
      image: "grade_3_young.png",
      description: "すくすく成長中！",
      color: "green",
      accuracy_min: 80,
      wpm_min: 30
    },
    "child" => {
      name: "子どものカワウソ",
      emoji: "🌊",
      image: "grade_2_child.png",
      description: "元気いっぱい練習中！",
      color: "cyan",
      accuracy_min: 70,
      wpm_min: 15
    },
    "baby" => {
      name: "赤ちゃんカワウソ",
      emoji: "🐣",
      image: "grade_1_baby.png",
      description: "よちよちスタート！",
      color: "gray",
      accuracy_min: 0,
      wpm_min: 0
    }
  }.freeze
end
