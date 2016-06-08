class AddStateToInstitutions < ActiveRecord::Migration
  def change
    add_column :institutions, :state, :string
  end
end
