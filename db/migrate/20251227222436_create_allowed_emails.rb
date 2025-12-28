class CreateAllowedEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :allowed_emails do |t|
      t.string :email, null: false
      t.boolean :active, default: true, null: false
      t.text :note

      t.timestamps
    end
    add_index :allowed_emails, :email, unique: true
  end
end
