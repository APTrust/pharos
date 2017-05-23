class CreateDpnWorkItems < ActiveRecord::Migration[4.2]
  def change
    create_table :dpn_work_items do |t|
      t.timestamps null: false
    end
  end
end
