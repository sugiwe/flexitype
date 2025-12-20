# frozen_string_literal: true

namespace :lessons do
  desc "Migrate lessons from YAML to database"
  task migrate_to_db: :environment do
    puts "YAMLデータをDBに移行します..."

    # YAMLファイルのパス
    yaml_file = Rails.root.join("config/typing_lessons.yml")
    unless File.exist?(yaml_file)
      puts "エラー: #{yaml_file} が見つかりません"
      exit 1
    end

    # YAMLデータを読み込み
    yaml_data = YAML.load_file(yaml_file)

    # 公式レッスン用ユーザーを取得
    official_user = User.find_by(email: "typnix.app@gmail.com")
    unless official_user
      puts "エラー: 公式レッスン用ユーザー（typnix.app@gmail.com）が見つかりません"
      puts "先に公式ユーザーを作成してください: bin/rails runner tmp/create_official_user.rb"
      exit 1
    end

    puts "公式ユーザー: #{official_user.email} (ID: #{official_user.id})"
    puts ""

    # カテゴリーとレッスンのカウント
    category_count = 0
    lesson_count = 0

    # カテゴリーごとにデータを移行
    yaml_data["lessons"].each_with_index do |(category_key, category_data), index|
      # カテゴリーを作成
      category = Category.find_or_create_by!(name: category_data["category"]) do |c|
        c.description = category_data["description"]
        c.display_order = index
        c.requires_login = category_data["requires_login"]
        c.premium = category_data["premium"]
      end

      puts "カテゴリー作成: #{category.name} (display_order: #{category.display_order})"
      category_count += 1

      # レッスンを作成
      category_data["lessons"].each do |lesson_data|
        lesson = Lesson.find_or_create_by!(
          user: official_user,
          category: category,
          name: lesson_data["name"]
        ) do |l|
          l.description = lesson_data["description"]
          l.items = lesson_data["items"]
          l.count = lesson_data["count"]
          l.requires_login = category_data["requires_login"]
          l.premium = category_data["premium"]
          l.is_public = true  # 公式レッスンはすべて公開
        end

        puts "  レッスン作成: #{lesson.name} (ID: #{lesson.id}, items: #{lesson.items.size}個)"
        lesson_count += 1
      end

      puts ""
    end

    puts "="*60
    puts "移行完了！"
    puts "  カテゴリー: #{category_count}個"
    puts "  レッスン: #{lesson_count}個"
    puts "="*60
  end
end
