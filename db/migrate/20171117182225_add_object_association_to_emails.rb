class AddObjectAssociationToEmails < ActiveRecord::Migration[5.1]
  def change
    add_column :emails, :object_id, :integer, default: nil
  end
end
