class RemoveHistoryLimitFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :history_limit, :integer, default: 50, null: false
  end
end
