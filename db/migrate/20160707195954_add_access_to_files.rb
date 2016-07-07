class AddAccessToFiles < ActiveRecord::Migration
  def change
    add_column :generic_files, :access, :string
  end
end
