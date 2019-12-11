class RemoveDpn < ActiveRecord::Migration[5.2]
  def change
    # Remove columns first, because they refer to dpn_tables
    remove_column(:institutions, :dpn_uuid)
    remove_column(:intellectual_objects, :dpn_uuid)

    drop_table(:dpn_work_items, if_exists: true)
    drop_table(:dpn_bags, if_exists: true)
  end
end
