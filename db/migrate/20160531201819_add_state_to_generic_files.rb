class AddStateToGenericFiles < ActiveRecord::Migration
  def change
    add_column :generic_files, :state, :string
  end
end
