class AddPeriodSummaryFieldsToShares < ActiveRecord::Migration[8.1]
  def change
    add_column :shares, :share_type, :string, default: "single", null: false
    add_column :shares, :period, :string
    add_column :shares, :start_date, :date
    add_column :shares, :end_date, :date
    add_column :shares, :user_id, :bigint

    add_index :shares, :share_type
    add_index :shares, :user_id
    add_foreign_key :shares, :users
  end
end
