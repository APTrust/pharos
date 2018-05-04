class AddStorageTypeToIntellectualObjects < ActiveRecord::Migration[5.2]
  def up
    puts "This migration takes a long time to run!"
    add_column :intellectual_objects, :storage_type, :string, default: 'Standard'

    batch_size = 5000
    count = 0
    IntellectualObject.find_in_batches(batch_size: batch_size) do |batch|
      IntellectualObject.transaction do
        batch.each do |io|
          io.storage_type = 'standard'
          io.save!
        end
      end
      count += 1
      puts "[#{Time.now}] Updated #{count * batch_size} IntellectualObjects"
    end
  end

  def down
    remove_column :intellectual_objects, :storage_type
  end
end
