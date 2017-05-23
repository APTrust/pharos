class AddStateToGenericFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :generic_files, :state, :string
  end
end
