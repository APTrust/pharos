class RemoveDpnBytesFromSnapshots < ActiveRecord::Migration[5.1]
  def change
    remove_column :snapshots, :dpn_bytes
  end
end
