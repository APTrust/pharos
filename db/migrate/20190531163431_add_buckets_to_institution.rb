class AddBucketsToInstitution < ActiveRecord::Migration[5.2]
  def up
    add_column :institutions, :repo_receiving_bucket, :string, default: nil
    add_column :institutions, :repo_restore_bucket, :string, default: nil
    add_column :institutions, :demo_receiving_bucket, :string, default: nil
    add_column :institutions, :demo_restore_bucket, :string, default: nil
  end

  def down
    remove_column :institutions, :repo_receiving_bucket
    remove_column :institutions, :repo_restore_bucket
    remove_column :institutions, :demo_receiving_bucket
    remove_column :institutions, :demo_restore_bucket
  end
end
