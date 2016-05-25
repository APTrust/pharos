class AddGroupsToIntellectualObjects < ActiveRecord::Migration
  def change
    add_column :intellectual_objects, :read_groups, :string
    add_column :intellectual_objects, :edit_groups, :string
    add_column :intellectual_objects, :discover_groups, :string
  end
end
