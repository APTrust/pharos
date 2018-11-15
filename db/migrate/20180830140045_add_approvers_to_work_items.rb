class AddApproversToWorkItems < ActiveRecord::Migration[5.2]
  def up
    add_column :work_items, :aptrust_approver, :string
    add_column :work_items, :inst_approver, :string
  end

  def down
    remove_column :work_items, :aptrust_approver, :string
    remove_column :work_items, :inst_approver, :string
  end
end
