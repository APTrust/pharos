class ChangeGenericFileIdentifierLength < ActiveRecord::Migration[5.1]
  def change
    def up
      change_column :generic_files, :identifier, :string, limit: 400
      change_column :premis_events, :generic_file_identifier, :string, limit: 400
      change_column :work_items, :generic_file_identifier, :string, limit: 400
    end

    def down
      change_column :generic_files, :identifier, :string, limit: 255
      change_column :premis_events, :generic_file_identifier, :string, limit: 255
      change_column :work_items, :generic_file_identifier, :string, limit: 255
    end
  end
end
