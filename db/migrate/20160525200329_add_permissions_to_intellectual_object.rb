class AddPermissionsToIntellectualObject < ActiveRecord::Migration[4.2]
  def change
    add_column :intellectual_objects, :permissions, :string
  end
end
