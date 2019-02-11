class AddObjectIdStateIndexToFiles < ActiveRecord::Migration[5.2]
  def change
    add_index :generic_files, [:intellectual_object_id, :state]
  end
end
