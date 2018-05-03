class AddEfficiencyIndexesForFiles < ActiveRecord::Migration[5.1]
  def change
    add_index :generic_files, [:institution_id, :state, :file_format], name: 'index_files_on_inst_state_and_format'
    add_index :generic_files, [:institution_id, :state, :updated_at], name: 'index_files_on_inst_state_and_updated'
    add_index :generic_files, [:institution_id, :updated_at]
    add_index :generic_files, [:state, :updated_at]
  end
end
