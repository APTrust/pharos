class UrlToStorageRecord < ActiveRecord::Migration[5.2]

  # This migration copies the old GenericFile.uri field into one
  # or more StorageRecords. The old system supported one URI per
  # file. The new system supports multiple.
  #
  # Items in standard storage

  # We're not testing for a regex. Those are literal slashes.
  def is_standard_storage_uri(uri)
    uri.include?('/aptrust.preservation.storage/') || uri.include?('/aptrust.test.preservation/')
  end

  # This returns the URI of the Glacier replication copy for
  # items in standard storage.
  def replication_uri(uri)
    if uri.include?('/aptrust.preservation.storage/')
      uri.sub('/aptrust.preservation.storage/', '/aptrust.preservation.oregon/')
    elsif uri.include?('/aptrust.test.preservation/')
      uri.sub('/aptrust.test.preservation/', '/aptrust.test.preservation.oregon/')
    end
  end

  # This is the actual migration:
  #
  # 1. Create GenericFile.UUID column
  # 2. Copy URI from GenericFile to StorageRecord(s)
  # 3. Drop GenericFile.uri column
  #
  def up
    add_column :generic_files, :uuid, :string, limit: 36

    # Copy old GenericFile.uri to StorageRecord
    GenericFile.all.each do |gf|

      gf.uuid = gf.uri.split('/').last
      gf.save!

      sr = StorageRecord.where(generic_file_id: gf.id, url: gf.uri).first
      if sr.nil?
        sr = StorageRecord.new(generic_file_id: gf.id, url: gf.uri)
        sr.save!
        if is_standard_storage_uri(gf.uri)
          glacier_uri = replication_uri(gf.uri)
          raise "Bad URI" if glacier_uri.blank?
          sr = StorageRecord.new(generic_file_id: gf.id, url: glacier_uri)
          sr.save!
        end
      end
    end

    # UUID should not be null and should be unique
    change_column :generic_files, :uuid, :string, null: false
    add_index :generic_files, :uuid, unique: true

    # Remove the old GenericFile.uri column
    remove_column :generic_files, :uri
  end


  # Revert back to the old state, where only the primary URI was stored
  # in the GenericFile record.
  def down
    add_column :generic_files, :uri, :string
    GenericFile.all.each do |gf|
      sr = StorageRecord.where(generic_file_id: gf.id).first
      raise "Bad URI for #{gf.identifier}" if sr.nil?
      gf.uri = sr.url
      gf.save!
    end
    change_column :generic_files, :uri, :string, null: false
    remove_index :generic_files, :uuid
    remove_column :generic_files, :uuid
  end

end
