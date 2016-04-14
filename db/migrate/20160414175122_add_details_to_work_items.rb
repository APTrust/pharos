class AddDetailsToWorkItems < ActiveRecord::Migration
  def change
    add_column :work_items, :name, :string
    add_column :work_items, :etag, :string
    add_column :work_items, :bucket, :string
    add_column :work_items, :user, :string
    add_column :work_items, :institution, :string
    add_column :work_items, :note, :text, limit: 255
    add_column :work_items, :action, :string
    add_column :work_items, :stage, :string
    add_column :work_items, :status, :string
    add_column :work_items, :outcome, :text, limit: 255
    add_column :work_items, :bag_date, :datetime
    add_column :work_items, :date, :datetime
    add_column :work_items, :retry, :boolean, default: false, null: false
    add_column :work_items, :reviewed, :boolean, default: false
    add_column :work_items, :object_identifier, :string
    add_column :work_items, :generic_file_identifier, :string
    add_column :work_items, :state, :text
    add_column :work_items, :node, :string, limit: 255
    add_column :work_items, :pid, :integer, default: 0
    add_column :work_items, :needs_admin_review, :boolean, default: false, null: false

    add_index :work_items, :action
    add_index :work_items, [:etag, :name]
    add_index :work_items, :institution
    add_index :work_items, :stage
    add_index :work_items, :status
  end
end
