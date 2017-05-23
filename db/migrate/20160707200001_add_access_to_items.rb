class AddAccessToItems < ActiveRecord::Migration[4.2]
  def change
    add_column :work_items, :access, :string
  end
end
