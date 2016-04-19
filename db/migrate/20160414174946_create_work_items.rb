class CreateWorkItems < ActiveRecord::Migration
  def change
    create_table :work_items do |t|
      t.timestamps null: false
      t.belongs_to :intellectual_object, index: true
      t.belongs_to :generic_file, index: true
    end
  end
end
