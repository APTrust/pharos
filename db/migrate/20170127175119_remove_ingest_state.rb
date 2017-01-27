class RemoveIngestState < ActiveRecord::Migration
  def change
    remove_column :intellectual_objects, :ingest_state
    remove_column :generic_files, :ingest_state
  end
end
