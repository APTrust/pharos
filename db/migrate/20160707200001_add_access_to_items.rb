class AddAccessToItems < ActiveRecord::Migration
  def change
    add_column :work_items, :access, :string
  end
end
