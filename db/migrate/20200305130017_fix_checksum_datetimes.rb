class FixChecksumDatetimes < ActiveRecord::Migration[5.2]
  def up
    # Note that the USING CAST part of this migration is
    # Postgres-specific.
    change_column :checksums, :datetime, 'timestamp USING CAST(datetime AS timestamp)'
  end

  def down
    change_column :checksums, :datetime, :string
  end
end
