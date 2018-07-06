class ChangeBaggingGroupIdentifierToBagGroupIdentifier < ActiveRecord::Migration[5.2]
 def up
    puts "This migration takes a long time to run!"
    rename_column :intellectual_objects, :bagging_group_identifier, :bag_group_identifier

    batch_size = 5000
    count = 0
    IntellectualObject.find_in_batches(batch_size: batch_size) do |batch|
      IntellectualObject.transaction do
        batch.each do |io|
          if io.bag_group_identifier.nil?
            io.bag_group_identifier = ''
            io.save!
          end
        end
      end
      count += 1
      puts "[#{Time.now}] Updated #{count * batch_size} IntellectualObjects"
    end

    change_column :intellectual_objects, :bag_group_identifier, :string, null: false, default: ""
  end

  def down
    change_column :intellectual_objects, :bag_group_identifier, :string, default: nil
    rename_column :intellectual_objects, :bag_group_identifier, :bagging_group_identifier
  end
end