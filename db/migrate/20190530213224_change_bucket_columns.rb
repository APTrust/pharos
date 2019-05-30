class ChangeBucketColumns < ActiveRecord::Migration[5.2]
  def up
    Institution.all.each do |inst|
      inst.repo_receiving_bucket = "aptrust.receiving.#{inst.identifier}"
      inst.repo_restore_bucket = "aptrust.restore.#{inst.identifier}"
      inst.demo_receiving_bucket = "aptrust.receiving.test#{inst.identifier}"
      inst.demo_restore_bucket = "aptrust.restore.test#{inst.identifier}"
      inst.save!
      puts "Updated Institution: #{inst.name}"
    end

    Institution.all.each do |inst|
      puts "checking: #{inst.repo_receiving_bucket}"
    end

    change_column :institutions, :repo_receiving_bucket, :string, null: false
    change_column :institutions, :repo_restore_bucket, :string, null: false
    change_column :institutions, :demo_receiving_bucket, :string, null: false
    change_column :institutions, :demo_restore_bucket, :string, null: false
  end

  def down
    change_column :institutions, :repo_receiving_bucket, :string, default: nil
    change_column :institutions, :repo_restore_bucket, :string, default: nil
    change_column :institutions, :demo_receiving_bucket, :string, default: nil
    change_column :institutions, :demo_restore_bucket, :string, default: nil
  end
end
