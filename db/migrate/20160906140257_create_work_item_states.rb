class CreateWorkItemStates < ActiveRecord::Migration
  def change
    create_table :work_item_states do |t|
      t.integer :work_item_id
      t.string :action, null: false
      t.binary :state, default: nil
      t.timestamps null: false
    end

    remove_column :work_items, :state
  end
end
