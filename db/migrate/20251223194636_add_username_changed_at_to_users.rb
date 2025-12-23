class AddUsernameChangedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username_changed_at, :datetime
  end
end
