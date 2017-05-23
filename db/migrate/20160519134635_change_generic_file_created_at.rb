class ChangeGenericFileCreatedAt < ActiveRecord::Migration[4.2]
  def change
    rename_column :generic_files, :created_at, :created
  end
end
