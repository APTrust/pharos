class ChangePremisEventColumnNames < ActiveRecord::Migration
  def change
    rename_column :premis_events, :event_identifier, :identifier
    rename_column :premis_events, :event_outcome, :outcome
    rename_column :premis_events, :event_date_time, :date_time
    rename_column :premis_events, :event_outcome_detail, :outcome_detail
    rename_column :premis_events, :event_detail, :detail
    rename_column :premis_events, :event_outcome_information, :outcome_information
    rename_column :premis_events, :event_object, :object
    rename_column :premis_events, :event_agent, :agent
  end
end
