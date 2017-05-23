class AddEventTypeIndexToPremisEvents < ActiveRecord::Migration[4.2]
  def change
    add_index :premis_events, [:event_type, :outcome]
  end
end
