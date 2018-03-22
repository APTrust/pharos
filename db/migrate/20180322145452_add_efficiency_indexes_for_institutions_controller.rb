class AddEfficiencyIndexesForInstitutionsController < ActiveRecord::Migration[5.1]
  def change
    add_index :generic_files, :institution_id
    add_index :generic_files, [:institution_id, :size, :state]
    add_index :generic_files, [:size, :state]
    add_index :generic_files, [:institution_id, :file_format, :state]
    add_index :generic_files, [:file_format, :state]
    add_index :intellectual_objects, [:institution_id, :state]
    add_index :work_items, [:institution_id, :date]
  end
end
