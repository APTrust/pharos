class AddEventTypeIndexToPremisEvents < ActiveRecord::Migration
  def change
    add_index :premis_events, [:event_type, :outcome]
  end
end
