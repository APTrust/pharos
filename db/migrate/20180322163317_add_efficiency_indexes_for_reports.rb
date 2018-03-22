class AddEfficiencyIndexesForReports < ActiveRecord::Migration[5.1]
  def change
    add_index :generic_files, :state
    add_index :generic_files, [:institution_id, :state]
  end
end
