class IndexFilesOnSize < ActiveRecord::Migration
  def change
    add_index :generic_files, :size
  end
end
