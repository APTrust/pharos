class ChangeSnapshotBytesColumnTypeToBigInt < ActiveRecord::Migration[5.2]
  def change
    change_column :snapshots, :apt_bytes, :bigint
  end
end
