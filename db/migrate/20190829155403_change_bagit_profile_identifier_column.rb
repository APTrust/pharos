class ChangeBagitProfileIdentifierColumn < ActiveRecord::Migration[5.2]
  def up
    change_column :intellectual_objects, :bagit_profile_identifier, :string
  end

  def down
    change_column :intellectual_objects, :bagit_profile_identifier, :text
  end
end
