class AddPermissionsToGenericFile < ActiveRecord::Migration[4.2]
  def change
    add_column :generic_files, :permissions, :string
  end
end
