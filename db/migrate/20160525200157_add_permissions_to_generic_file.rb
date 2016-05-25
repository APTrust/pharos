class AddPermissionsToGenericFile < ActiveRecord::Migration
  def change
    add_column :generic_files, :permissions, :string
  end
end
