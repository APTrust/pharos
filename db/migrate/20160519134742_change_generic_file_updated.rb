class ChangeGenericFileUpdated < ActiveRecord::Migration[4.2]
  def change
    rename_column :generic_files, :updated, :modified
  end
end
