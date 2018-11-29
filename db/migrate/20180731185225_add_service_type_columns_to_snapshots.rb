class AddServiceTypeColumnsToSnapshots < ActiveRecord::Migration[5.2]
  def change
    add_column :snapshots, :cs_bytes, :bigint
    add_column :snapshots, :go_bytes, :bigint
  end
end
