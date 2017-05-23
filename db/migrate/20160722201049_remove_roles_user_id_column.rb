class RemoveRolesUserIdColumn < ActiveRecord::Migration[4.2]
  def change
    remove_column :roles, :user_id
  end
end
