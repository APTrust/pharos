class IndexEventsOnDate < ActiveRecord::Migration[4.2]
  def change
    add_index :premis_events, :date_time
  end
end
