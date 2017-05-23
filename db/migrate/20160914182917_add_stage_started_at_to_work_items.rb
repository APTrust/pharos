class AddStageStartedAtToWorkItems < ActiveRecord::Migration[4.2]
  def change
    add_column :work_items, :stage_started_at, :datetime, default: nil
  end
end
