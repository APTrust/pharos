class AddStateToWorkItem < ActiveRecord::Migration[4.2]
  def change
    add_column :work_items, :work_item_state_id, :integer
  end
end
