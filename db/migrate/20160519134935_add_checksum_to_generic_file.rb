class AddChecksumToGenericFile < ActiveRecord::Migration
  def change
    add_foreign_key :checksums, :generic_files
  end
end
