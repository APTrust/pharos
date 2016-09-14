class AddStageStartedAtToWorkItems < ActiveRecord::Migration
  def change
    add_column :work_items, :stage_started_at, :datetime, default: nil
  end
end
