class RenameEventProperties < ActiveRecord::Migration
  def change
    change_table :premis_events do |t|
      t.rename :event_identifier, :identifier
      t.rename :event_outcome, :outcome
      t.rename :event_date_time, :date_time
      t.rename :event_outcome_detail, :outcome_detail
      t.rename :event_detail, :detail
      t.rename :event_outcome_information, :outcome_information
      t.rename :event_object, :object
      t.rename :event_agent, :agent
    end
  end
end
