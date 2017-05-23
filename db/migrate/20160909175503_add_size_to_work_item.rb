class AddSizeToWorkItem < ActiveRecord::Migration[4.2]
  def change
    add_column :work_items, :size, :integer, default: nil
  end
end
