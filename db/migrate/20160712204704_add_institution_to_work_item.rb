class AddInstitutionToWorkItem < ActiveRecord::Migration
  def change
    add_column :work_items, :institution_id, :integer
  end
end
