class RemoveUnusedColumns < ActiveRecord::Migration
  def change
    remove_column :generic_files, :intellectual_object, :string
    remove_column :generic_files, :content_dsLocation, :string
    remove_column :generic_files, :access, :string
    remove_column :generic_files, :institution_id, :integer
    remove_column :institutions, :user_id, :integer
    remove_column :intellectual_objects, :institution, :string
    remove_column :intellectual_objects, :permissions, :string
    remove_column :users, :institution, :string
    remove_column :work_items, :institution, :string
    remove_column :work_items, :access, :string
  end
end
