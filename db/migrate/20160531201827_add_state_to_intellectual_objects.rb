class AddStateToIntellectualObjects < ActiveRecord::Migration[4.2]
  def change
    add_column :intellectual_objects, :state, :string
  end
end
