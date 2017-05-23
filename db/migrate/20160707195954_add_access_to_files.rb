class AddAccessToFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :generic_files, :access, :string
  end
end
