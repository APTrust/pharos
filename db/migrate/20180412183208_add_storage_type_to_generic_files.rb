class AddStorageTypeToGenericFiles < ActiveRecord::Migration[5.1]
  def up
    puts "This migration takes a long time to run!"
    add_column :generic_files, :storage_type, :string, default: 'standard'

    batch_size = 5000
    count = 0
    GenericFile.find_in_batches(batch_size: batch_size) do |batch|
      GenericFile.transaction do
        batch.each do |gf|
          gf.storage_type = 'standard'
          gf.save!
        end
      end
      count += 1
      puts "[#{Time.now}] Updated #{count * batch_size} GenericFiles"
    end
  end

  def down
    remove_column :generic_files, :storage_type
  end
end
