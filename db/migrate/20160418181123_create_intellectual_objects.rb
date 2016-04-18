class CreateIntellectualObjects < ActiveRecord::Migration
  def change
    create_table :intellectual_objects do |t|
      t.string :title
      t.text :description
      t.string :identifier
      t.string :alt_identifier
      t.string :access
      t.string :bag_name

      t.timestamps null: false
    end
  end
end
