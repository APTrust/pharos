class AddInstToEvents < ActiveRecord::Migration[4.2]
  def change
    remove_column :premis_events, :outcome
    add_column :premis_events, :outcome, :string
    add_column :premis_events, :institution_id, :integer
  end
end
