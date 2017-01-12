class IndexEventsOnDate < ActiveRecord::Migration
  def change
    add_index :premis_events, :date_time
  end
end
