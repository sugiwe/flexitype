class RemoveAccessControlFromLessons < ActiveRecord::Migration[8.1]
  def change
    remove_column :lessons, :requires_login, :boolean
    remove_column :lessons, :premium, :boolean
  end
end
