class AddEfficiencyIndexesToObjects < ActiveRecord::Migration[5.1]
  def change
    add_index :intellectual_objects, :bag_name
    add_index :intellectual_objects, :created_at
    add_index :intellectual_objects, :state
    add_index :generic_files, [:intellectual_object_id , :file_format]
  end
end
