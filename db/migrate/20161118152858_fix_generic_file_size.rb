class FixGenericFileSize < ActiveRecord::Migration[4.2]
  def change
    change_column :generic_files, :size, :bigint
  end
end
