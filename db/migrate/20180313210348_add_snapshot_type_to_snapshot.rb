class AddSnapshotTypeToSnapshot < ActiveRecord::Migration[5.1]
  def change
    add_column :snapshots, :snapshot_type, :string
  end
end
