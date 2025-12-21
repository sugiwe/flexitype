namespace :lessons do
  desc "Migrate lessons from YAML to database"
  task migrate_from_yaml: :environment do
    require "yaml"

    puts "=== YAMLからDBへのデータ移行開始 ==="

    # 管理者ユーザーを取得
    admin_email = ENV["ADMIN_EMAILS"]&.split(",")&.first&.strip
    admin_user = User.find_by(email: admin_email)

    unless admin_user
      puts "エラー: 管理者ユーザーが見つかりません (#{admin_email})"
      exit 1
    end

    puts "管理者ユーザー: #{admin_user.email}"

    # YAMLファイルを読み込み
    yaml_path = Rails.root.join("config", "typing_lessons.yml")
    unless File.exist?(yaml_path)
      puts "エラー: YAMLファイルが見つかりません (#{yaml_path})"
      exit 1
    end

    lessons_data = YAML.load_file(yaml_path)

    # カテゴリーとレッスンのマッピング
    category_order = 0
    lesson_count = 0

    lessons_data["lessons"].each do |key, group_data|
      # カテゴリーを作成
      category = Category.find_or_create_by!(name: group_data["category"]) do |c|
        c.description = group_data["description"]
        c.display_order = category_order
        c.requires_login = group_data["requires_login"]
        c.premium = group_data["premium"]
      end

      puts "カテゴリー: #{category.name} (ID: #{category.id})"
      category_order += 1

      # レッスンを作成（YAMLのtype、idフィールドは無視）
      group_data["lessons"].each do |lesson_data|
        lesson = Lesson.create!(
          user: admin_user,
          category: category,
          name: lesson_data["name"],
          description: lesson_data["description"],
          items: lesson_data["items"],
          count: lesson_data["count"],
          is_public: true,
          requires_login: group_data["requires_login"],
          premium: group_data["premium"]
        )
        lesson_count += 1
        puts "  レッスン作成: #{lesson.name} (#{lesson.items.size}項目, #{lesson.count}問)"
      end
    end

    puts ""
    puts "=== 移行完了 ==="
    puts "カテゴリー数: #{Category.count}"
    puts "レッスン数: #{Lesson.count}"
    puts "作成されたレッスン: #{lesson_count}件"
  end
end
