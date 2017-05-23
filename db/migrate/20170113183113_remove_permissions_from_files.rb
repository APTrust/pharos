class RemovePermissionsFromFiles < ActiveRecord::Migration[4.2]
  def change
    remove_column :generic_files, :permissions
  end
end
