class AddContentToGenericFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :generic_files, :content_dsLocation, :string
  end
end
