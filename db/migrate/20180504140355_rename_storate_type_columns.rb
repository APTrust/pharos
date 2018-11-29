class RenameStorateTypeColumns < ActiveRecord::Migration[5.2]
  def up
    rename_column :generic_files, :storage_type, :storage_option
    rename_column :intellectual_objects, :storage_type, :storage_option
  end

  def down
    rename_column :generic_files, :storage_option, :storage_type
    rename_column :intellectual_objects, :storage_option, :storage_type
  end
end
