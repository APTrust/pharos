class MakeFileInstitutionIdNotNil < ActiveRecord::Migration[5.1]
  def change
    change_column :generic_files, :institution_id, :integer, null: false
  end
end
