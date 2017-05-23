class DpnStateAsText < ActiveRecord::Migration[4.2]
  def change
    # state should be text field without length limit
    change_column :dpn_work_items, :state, :text, default: nil
  end
end
