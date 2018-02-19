class SnapshotCostDecimal < ActiveRecord::Migration[5.1]
  def change
    change_column :snapshots, :cost, :decimal
  end
end