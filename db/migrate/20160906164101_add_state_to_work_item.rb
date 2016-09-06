class AddStateToWorkItem < ActiveRecord::Migration
  def change
    add_column :work_items, :work_item_state_id, :integer
  end
end
