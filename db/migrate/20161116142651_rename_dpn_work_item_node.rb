class RenameDpnWorkItemNode < ActiveRecord::Migration[4.2]
  def change
    rename_column :dpn_work_items, :node, :remote_node
  end
end
