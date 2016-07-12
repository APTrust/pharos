class AddInstitutionToGenericFile < ActiveRecord::Migration
  def change
    add_column :generic_files, :institution_id, :integer
  end
end
