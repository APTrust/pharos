class AddBtrAttributesToIntellectualObjects < ActiveRecord::Migration[5.2]
  def up
    add_column :intellectual_objects, :bagit_profile_identifier, :text, default: nil
    add_column :intellectual_objects, :source_organization, :string
    add_column :intellectual_objects, :internal_sender_identifier, :string
    add_column :intellectual_objects, :internal_sender_description, :text
  end

  def down
    remove_column :intellectual_objects, :bagit_profile_identifier
    remove_column :intellectual_objects, :source_organization
    remove_column :intellectual_objects, :internal_sender_identifier
    remove_column :intellectual_objects, :internal_sender_description
  end
end
