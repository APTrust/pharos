class ChangeNewBucketAttributes < ActiveRecord::Migration[5.2]
  def up
    change_column :institutions, :receiving_bucket, :string, null: false
    change_column :institutions, :restore_bucket, :string, null: false
  end

  def down
    change_column :institutions, :receiving_bucket, :string, default: nil
    change_column :institutions, :restore_bucket, :string, default: nil
  end
end
