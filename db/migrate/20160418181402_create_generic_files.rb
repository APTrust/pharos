class CreateGenericFiles < ActiveRecord::Migration
  def change
    create_table :generic_files do |t|
      t.string :file_format
      t.string :uri
      t.float :size
      t.string :identifier
      t.string :intellectual_object
      t.belongs_to :intellectual_object, index: true
      t.timestamps null: false
    end
  end
end
