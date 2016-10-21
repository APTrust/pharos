class CreateDpnWorkItems < ActiveRecord::Migration
  def change
    create_table :dpn_work_items do |t|
      t.timestamps null: false
    end
  end
end
