class RemovePermissionsFromFiles < ActiveRecord::Migration
  def change
    remove_column :generic_files, :permissions
  end
end
