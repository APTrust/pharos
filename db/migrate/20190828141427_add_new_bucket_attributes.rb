class AddNewBucketAttributes < ActiveRecord::Migration[5.2]
  def up
    add_column :institutions, :receiving_bucket, :string, default: nil
    add_column :institutions, :restore_bucket, :string, default: nil

    Institution.all.each do |inst|
      inst.receiving_bucket = "#{Pharos::Application.config.pharos_receiving_bucket_prefix}#{inst.identifier}"
      inst.restore_bucket = "#{Pharos::Application.config.pharos_restore_bucket_prefix}#{inst.identifier}"
      inst.save!
      puts "Updated Institution: #{inst.name}"
    end
  end

  def down
    remove_column :institutions, :receiving_bucket
    remove_column :institutions, :restore_bucket
  end
end
