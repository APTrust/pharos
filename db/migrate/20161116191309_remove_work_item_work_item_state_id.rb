class RemoveWorkItemWorkItemStateId < ActiveRecord::Migration
  def change
    remove_column :work_items, :work_item_state_id
  end
end
