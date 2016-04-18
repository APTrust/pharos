class CreateChecksums < ActiveRecord::Migration
  def change
    create_table :checksums do |t|
      t.string :algorithm
      t.string :datetime
      t.string :digest

      t.timestamps null: false
    end
  end
end
