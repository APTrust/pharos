class AddTwoFactorEnabledCheckToInstitution < ActiveRecord::Migration[5.2]
  def up
    add_column :institutions, :otp_enabled, :boolean
  end

  def down
    remove_column :institutions, :otp_enabled
  end
end
