class ChangeGenericFileUpdated < ActiveRecord::Migration
  def change
    rename_column :generic_files, :updated, :modified
  end
end
