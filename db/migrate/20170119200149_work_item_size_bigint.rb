class WorkItemSizeBigint < ActiveRecord::Migration
  def change
    change_column :work_items, :size, :integer, limit: 8
  end
end
