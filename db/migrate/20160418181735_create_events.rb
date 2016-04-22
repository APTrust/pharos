class CreateEvents < ActiveRecord::Migration
  def change
    create_table :premis_events do |t|
      t.string :event_identifier
      t.string :event_type
      t.text :event_outcome
      t.string :event_date_time
      t.string :event_outcome_detail
      t.string :event_detail
      t.string :event_outcome_information
      t.string :event_object
      t.string :event_agent
      t.belongs_to :intellectual_object, index: true
      t.belongs_to :generic_file, index: true
      t.timestamps null: false
    end
  end
end
