class GenericFilesLastFixity < ActiveRecord::Migration
  def up
    puts "This migration takes a long time to run!"
    add_index :premis_events, [:generic_file_id, :event_type]
    add_column :generic_files, :last_fixity_check, :datetime, null: false, default: '2000-01-01'

    batch_size = 5000
    count = 0
    GenericFile.where(last_fixity_check: '2000-01-01').find_in_batches(batch_size: batch_size) do |batch|
      GenericFile.transaction do
        batch.each do |gf|
          last_fixity = gf.premis_events.where(event_type: 'fixity check').order('date_time desc').limit(1).pluck(:date_time).first
          if last_fixity.nil?
            cs = gf.checksums.where(algorithm: 'sha256').order('datetime desc').limit(1).first
            if cs
              last_fixity = cs.datetime
            else
              last_fixity = gf.last_fixity
            end
          end
          gf.last_fixity_check = last_fixity
          gf.save(validate: false)
        end
      end
      count += 1
      puts "[#{Time.now}] Updated #{count * batch_size} GenericFiles"
    end
  end

  def down
    remove_index :premis_events, [:generic_file_id, :event_type]
    remove_column :generic_files, :last_fixity_check
  end
end
