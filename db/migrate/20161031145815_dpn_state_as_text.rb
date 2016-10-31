class DpnStateAsText < ActiveRecord::Migration
  def change
    # state should be text field without length limit
    change_column :dpn_work_items, :state, :text, default: nil
  end
end
