class IndexFilesOnCreatedAt < ActiveRecord::Migration[5.1]
  def change
    add_index :generic_files, :created_at
  end
end
