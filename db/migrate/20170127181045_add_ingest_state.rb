class AddIngestState < ActiveRecord::Migration
  def change
    add_column :intellectual_objects, :ingest_state, :text, default: nil
    add_column :generic_files, :ingest_state, :text, default: nil
  end
end
