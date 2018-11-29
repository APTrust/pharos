class AddInstitutionAndRelationsToEmails < ActiveRecord::Migration[5.2]
  def up
    add_column :emails, :institution_id, :integer

    create_table :emails_generic_files, id: false do |t|
      t.belongs_to :generic_file, index: true
      t.belongs_to :email, index: true
    end

    create_table :emails_intellectual_objects, id: false do |t|
      t.belongs_to :intellectual_object, index: true
      t.belongs_to :email, index: true
    end
  end

  def down
    remove_column :emails, :institution_id, :integer

    drop_table :emails_generic_files

    drop_table :emails_intellectual_objects
  end
end
