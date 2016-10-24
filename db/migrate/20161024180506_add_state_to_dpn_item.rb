class AddStateToDpnItem < ActiveRecord::Migration
  def change
    add_column :dpn_work_items, :state, :text, limit: 255, default: nil
  end
end
