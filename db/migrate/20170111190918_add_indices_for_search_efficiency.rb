class AddIndicesForSearchEfficiency < ActiveRecord::Migration
  def change
    add_index :premis_events, :intellectual_object_identifier
    add_index :premis_events, :generic_file_identifier
    add_index :premis_events, :institution_id
    add_index :premis_events, :event_type
    add_index :premis_events, :outcome

    add_index :work_items, :institution_id

    add_index :generic_files, :institution_id
    add_index :generic_files, :file_format

    add_index :intellectual_objects, :access
  end
end
