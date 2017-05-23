class WorkItemSizeBigint < ActiveRecord::Migration[4.2]
  def change
    change_column :work_items, :size, :integer, limit: 8
  end
end
