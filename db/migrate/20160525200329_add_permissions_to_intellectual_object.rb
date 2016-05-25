class AddPermissionsToIntellectualObject < ActiveRecord::Migration
  def change
    add_column :intellectual_objects, :permissions, :string
  end
end
