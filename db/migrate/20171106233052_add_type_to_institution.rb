class AddTypeToInstitution < ActiveRecord::Migration[5.1]
  def change
    add_column :institutions, :type, :string
    add_column :institutions, :member_institution_id, :integer, default: nil
  end
end
