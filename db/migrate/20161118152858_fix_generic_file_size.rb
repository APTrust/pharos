class FixGenericFileSize < ActiveRecord::Migration
  def change
    change_column :generic_files, :size, :bigint
  end
end
