class AddStorageTypeToIntellectualObjects < ActiveRecord::Migration[5.2]
  def up
    puts "This migration takes a long time to run!"
    add_column :intellectual_objects, :storage_type, :string, null: false, default: 'Standard'
  end

  def down
    remove_column :intellectual_objects, :storage_type
  end
end
