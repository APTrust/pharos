class AddStateToIntellectualObjects < ActiveRecord::Migration
  def change
    add_column :intellectual_objects, :state, :string
  end
end
