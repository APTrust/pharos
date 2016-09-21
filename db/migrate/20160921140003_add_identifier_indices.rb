class AddIdentifierIndices < ActiveRecord::Migration
  def change
    add_index :intellectual_objects, :identifier, unique: true
    add_index :generic_files, :identifier, unique: true
    add_index :premis_events, :identifier, unique: true
  end
end
