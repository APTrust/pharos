class AddInstitutionToGenericFile < ActiveRecord::Migration[4.2]
  def change
    add_column :generic_files, :institution_id, :integer
  end
end
