class CreateWorkItems < ActiveRecord::Migration
  def change
    create_table :work_items do |t|

      t.timestamps null: false
    end
  end
end
