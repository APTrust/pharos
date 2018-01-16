class CreateSnapshots < ActiveRecord::Migration[5.1]
  def change
    create_table :snapshots do |t|
      t.datetime :audit_date
      t.integer :institution_id
      t.integer :apt_bytes
      t.integer :dpn_bytes
      t.integer :cost

      t.timestamps
    end
  end
end
