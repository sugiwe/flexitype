class AddNotifiedAtToAllowedEmails < ActiveRecord::Migration[8.1]
  def change
    add_column :allowed_emails, :notified_at, :datetime
  end
end
