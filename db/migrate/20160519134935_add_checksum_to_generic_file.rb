class AddChecksumToGenericFile < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key :checksums, :generic_files
  end
end
