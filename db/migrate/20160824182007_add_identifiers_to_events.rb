class AddIdentifiersToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :premis_events, :intellectual_object_identifier, :string
    add_column :premis_events, :generic_file_identifier, :string
  end
end
