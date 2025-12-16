class AddHistoryLimitToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :history_limit, :integer, null: false, default: 50
  end
end
