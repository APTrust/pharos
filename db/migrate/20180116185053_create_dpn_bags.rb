class CreateDpnBags < ActiveRecord::Migration[5.1]
  def change
    create_table :dpn_bags do |t|
      t.integer :institution_id
      t.string :object_identifier
      t.string :dpn_identifier
      t.integer :dpn_size
      t.string :node_1
      t.string :node_2
      t.string :node_3
      t.datetime :dpn_created_at
      t.datetime :dpn_updated_at

      t.timestamps
    end
  end
end
