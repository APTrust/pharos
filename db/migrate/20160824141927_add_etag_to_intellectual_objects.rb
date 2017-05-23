class AddEtagToIntellectualObjects < ActiveRecord::Migration[4.2]
  def change
    add_column :intellectual_objects, :etag, :string, default: nil
    add_column :intellectual_objects, :dpn_uuid, :string, default: nil
  end
end
