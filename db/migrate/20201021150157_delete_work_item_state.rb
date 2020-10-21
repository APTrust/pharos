class DeleteWorkItemState < ActiveRecord::Migration[5.2]
  def change
    drop_table :work_item_states
  end
end
