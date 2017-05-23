class ChangeGenericFileColumns < ActiveRecord::Migration[4.2]
  def change
    rename_column :generic_files, :updated_at, :updated
  end
end
