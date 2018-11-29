class AddRetryStageStatusToDpnWorkItem < ActiveRecord::Migration[5.2]
  def up
    add_column :dpn_work_items, :retry, :boolean, default: true, null: false
    add_column :dpn_work_items, :stage, :string, default: nil
    add_column :dpn_work_items, :status, :string, default: nil
  end

  def down
    remove_column :dpn_work_items, :retry
    remove_column :dpn_work_items, :stage
    remove_column :dpn_work_items, :status
  end
end
