class AddBagGroupIdentifierToObjects < ActiveRecord::Migration[5.1]
  def change
    add_column :intellectual_objects, :bagging_group_identifier, :string, default: nil, limit: 255
  end
end
