class CreateEmails < ActiveRecord::Migration[5.1]
  def change
    create_table :emails do |t|
      t.string :email_type
      t.string :event_identifier, default: nil
      t.integer :item_id, default: nil
      t.text :email_text, default: nil
      t.text :user_list, default: nil

      t.timestamps
    end
  end
end
