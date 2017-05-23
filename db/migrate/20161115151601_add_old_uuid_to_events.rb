class AddOldUuidToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :premis_events, :old_uuid, :string, default: nil
  end
end
