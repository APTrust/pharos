class AddStorageTypeToGenericFiles < ActiveRecord::Migration[5.1]
  def up
    puts "This migration takes a long time to run!"
    add_column :generic_files, :storage_type, :string, null: false, default: 'Standard'
  end

  def down
    remove_column :generic_files, :storage_type
  end
end
