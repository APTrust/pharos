class CreateSnapshots < ActiveRecord::Migration[5.1]
  def change
    create_table :snapshots do |t|
      t.audit_date :datetime
      t.institution_id :integer
      t.apt_bytes :integer
      t.dpn_bytes :integer

      t.timestamps
    end
  end
end
