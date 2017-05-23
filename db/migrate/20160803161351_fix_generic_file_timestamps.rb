class FixGenericFileTimestamps < ActiveRecord::Migration[4.2]
  def change
    rename_column :generic_files, :created, :created_at
    rename_column :generic_files, :modified, :updated_at
  end
end
