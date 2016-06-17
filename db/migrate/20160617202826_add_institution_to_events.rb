class AddInstitutionToEvents < ActiveRecord::Migration
  def change
    add_column :premis_events, :institution_id, :integer
  end
end
