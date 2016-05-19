class ChangeGenericFileColumns < ActiveRecord::Migration
  def change
    rename_column :generic_files, :updated_at, :updated
  end
end
