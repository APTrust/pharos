class ChangeObjectIdColumnNameOnEmails < ActiveRecord::Migration[5.1]
  def change
    remove_column :emails, :object_id
    add_column :emails, :intellectual_object_id, :integer, default: nil
  end
end
