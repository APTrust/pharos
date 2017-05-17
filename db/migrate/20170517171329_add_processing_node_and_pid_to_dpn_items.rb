class AddProcessingNodeAndPidToDpnItems < ActiveRecord::Migration[5.0]
  def change
    add_column :dpn_work_items, :processing_node, :string, limit: 255, default: nil
    add_column :dpn_work_items, :pid, :integer, default: 0
  end
end
