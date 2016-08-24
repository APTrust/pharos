class AddIdentifiersToEvents < ActiveRecord::Migration
  def change
    add_column :premis_events, :intellectual_object_identifier, :string
    add_column :premis_events, :generic_file_identifier, :string
  end
end
