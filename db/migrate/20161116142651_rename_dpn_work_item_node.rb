class RenameDpnWorkItemNode < ActiveRecord::Migration
  def change
    rename_column :dpn_work_items, :node, :remote_node
  end
end
