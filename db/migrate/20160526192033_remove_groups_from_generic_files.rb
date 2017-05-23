class RemoveGroupsFromGenericFiles < ActiveRecord::Migration[4.2]
  def change
    remove_column :generic_files, :read_groups, :string
    remove_column :generic_files, :edit_groups, :string
    remove_column :generic_files, :discover_groups, :string
  end
end
