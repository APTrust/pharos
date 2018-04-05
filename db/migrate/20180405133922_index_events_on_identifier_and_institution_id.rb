class IndexEventsOnIdentifierAndInstitutionId < ActiveRecord::Migration[5.1]
  def change
    add_index :premis_events, [:identifier, :institution_id]
  end
end
