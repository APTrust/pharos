class EnsurePremisEventIdentifiersNotNull < ActiveRecord::Migration
  def change
    remove_column :premis_events, :intellectual_object_identifier
    remove_column :premis_events, :generic_file_identifier
    add_column :premis_events, :intellectual_object_identifier, :string, null: false, default: ''
    add_column :premis_events, :generic_file_identifier, :string, null: false, default: ''
  end
end
