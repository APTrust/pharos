class AddQueuedAtToWorkItems < ActiveRecord::Migration[4.2]
  def change
    add_column :work_items, :queued_at, :datetime, default: nil
    remove_column :work_items, :state
    add_column :work_items, :state, :binary, default: nil
  end
end
