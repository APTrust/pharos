class RemoveReviewedFromWorkItems < ActiveRecord::Migration[4.2]
  def change
    remove_column :work_items, :reviewed
  end
end
