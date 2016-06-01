class ChangeEventOutcomeColumnType < ActiveRecord::Migration
  def change
    remove_column :premis_events, :outcome
    add_column :premis_events, :outcome, :string
  end
end
