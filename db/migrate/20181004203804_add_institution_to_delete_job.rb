class AddInstitutionToDeleteJob < ActiveRecord::Migration[5.2]
  def up
    add_column :bulk_delete_jobs, :institution_id, :integer, null: false
  end

  def down
    remove_column :bulk_delete_jobs, :institution_id
  end
end
