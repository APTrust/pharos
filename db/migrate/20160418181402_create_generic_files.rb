class CreateGenericFiles < ActiveRecord::Migration
  def change
    create_table :generic_files do |t|
      t.string :file_format
      t.string :uri
      t.long :size
      t.string :identifier
      t.belongs_to :intellectual_object, index: true
      t.timestamps null: false
    end
  end
end
