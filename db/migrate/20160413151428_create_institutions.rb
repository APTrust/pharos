class CreateInstitutions < ActiveRecord::Migration
  def change
    create_table :institutions do |t|
      t.string :name
      t.string :brief_name
      t.string :identifier
      t.string :dpn_uuid
      t.timestamps null: false
    end
  end
end
