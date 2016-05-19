class ChangeGenericFileCreatedAt < ActiveRecord::Migration
  def change
    rename_column :generic_files, :created_at, :created
  end
end
