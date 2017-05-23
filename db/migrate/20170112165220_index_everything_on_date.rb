class IndexEverythingOnDate < ActiveRecord::Migration[4.2]
  def change
    add_index :institutions, :name
    add_index :work_items, :date
    add_index :intellectual_objects, :updated_at
    add_index :generic_files, :updated_at
  end
end
