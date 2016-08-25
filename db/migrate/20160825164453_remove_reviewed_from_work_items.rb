class RemoveReviewedFromWorkItems < ActiveRecord::Migration
  def change
    remove_column :work_items, :reviewed
  end
end
