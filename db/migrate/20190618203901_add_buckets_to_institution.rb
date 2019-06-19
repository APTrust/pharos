class AddBucketsToInstitution < ActiveRecord::Migration[5.2]
  def up
    add_column :institutions, :repo_receiving_bucket, :string, default: nil
    add_column :institutions, :repo_restore_bucket, :string, default: nil
    add_column :institutions, :demo_receiving_bucket, :string, default: nil
    add_column :institutions, :demo_restore_bucket, :string, default: nil

    Institution.all.each do |inst|
      inst.repo_receiving_bucket = "aptrust.receiving.#{inst.identifier}"
      inst.repo_restore_bucket = "aptrust.restore.#{inst.identifier}"
      inst.demo_receiving_bucket = "aptrust.receiving.test.#{inst.identifier}"
      inst.demo_restore_bucket = "aptrust.restore.test.#{inst.identifier}"
      inst.save!
      puts "Updated Institution: #{inst.name}"
    end
  end

  def down
    remove_column :institutions, :repo_receiving_bucket
    remove_column :institutions, :repo_restore_bucket
    remove_column :institutions, :demo_receiving_bucket
    remove_column :institutions, :demo_restore_bucket
  end
end
