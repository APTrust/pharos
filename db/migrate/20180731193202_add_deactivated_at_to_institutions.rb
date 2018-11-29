class AddDeactivatedAtToInstitutions < ActiveRecord::Migration[5.2]
  def change
    add_column :institutions, :deactivated_at, :datetime, default: nil
  end
end
