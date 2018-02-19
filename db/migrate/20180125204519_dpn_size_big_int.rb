class DpnSizeBigInt < ActiveRecord::Migration[5.1]
  def change
    change_column :dpn_bags, :dpn_size, :bigint
  end
end
