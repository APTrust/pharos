class AddInstitutionToWorkItem < ActiveRecord::Migration[4.2]
  def change
    add_column :work_items, :institution_id, :integer
  end
end
