class AddInstitutionIdToFiles < ActiveRecord::Migration[5.1]
  def up
    puts "This migration takes a long time to run!"
    add_column :generic_files, :institution_id, :integer, default: nil

    batch_size = 5000
    count = 0
    GenericFile.where(last_fixity_check: '2000-01-01').find_in_batches(batch_size: batch_size) do |batch|
      GenericFile.transaction do
        batch.each do |gf|
          gf.institution_id = gf.intellectual_object.institution_id
          gf.save!
        end
      end
      count += 1
      puts "[#{Time.now}] Updated #{count * batch_size} GenericFiles"
    end
  end

  def down
    remove_column :generic_files, :institution_id
  end
end
