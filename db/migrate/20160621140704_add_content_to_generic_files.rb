class AddContentToGenericFiles < ActiveRecord::Migration
  def change
    add_column :generic_files, :content_dsLocation, :string
  end
end
