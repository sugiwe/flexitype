class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  def change
    # まずはnull許可でカラム追加
    add_column :users, :username, :string

    # 既存ユーザーにusernameを自動生成
    reversible do |dir|
      dir.up do
        User.find_each do |user|
          # Gmailアドレスの@の前の部分を取得
          username_base = user.email.split("@").first.downcase

          # 既存のusernameと重複しないようにする
          username = username_base
          counter = 1
          while User.exists?(username: username)
            username = "#{username_base}#{counter}"
            counter += 1
          end

          user.update_column(:username, username)
        end
      end
    end

    # null制約を追加
    change_column_null :users, :username, false

    # ユニークインデックスを追加
    add_index :users, :username, unique: true
  end
end
