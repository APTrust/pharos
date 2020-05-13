class CreateStorageRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :storage_records do |t|
      t.integer :generic_file_id, index: true
      t.string :url, unique: true
    end
    add_foreign_key :storage_records, :generic_files
  end
end