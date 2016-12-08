class AddOldUuidToEvents < ActiveRecord::Migration
  def change
    add_column :premis_events, :old_uuid, :string, default: nil
  end
end
