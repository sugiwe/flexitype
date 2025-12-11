class AddIconUrlAndValidationsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :icon_url, :string, limit: 4096
    change_column :users, :email, :string, limit: 254, null: false
    change_column :users, :name, :string, limit: 30, null: false
  end
end
