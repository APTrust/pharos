class RemoveWorkItemWorkItemStateId < ActiveRecord::Migration[4.2]
  def change
    remove_column :work_items, :work_item_state_id
  end
end
