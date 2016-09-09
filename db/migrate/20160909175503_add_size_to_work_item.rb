class AddSizeToWorkItem < ActiveRecord::Migration
  def change
    add_column :work_items, :size, :integer, default: nil
  end
end
