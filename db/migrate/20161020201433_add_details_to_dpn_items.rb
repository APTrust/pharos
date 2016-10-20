class AddDetailsToDpnItems < ActiveRecord::Migration
  def change
    add_column :dpn_work_items, :node, :string, limit: 20, default: '', null: false
    add_column :dpn_work_items, :task, :string, limit: 40, default: '', null: false
    add_column :dpn_work_items, :identifier, :string, limit: 40, default: '', null: false
    add_column :dpn_work_items, :queued_at, :datetime, default: nil
    add_column :dpn_work_items, :completed_at, :datetime, default: nil
    add_column :dpn_work_items, :note, :string, limit: 400, default: nil

    add_index :dpn_work_items, :identifier, unique: false
    add_index :dpn_work_items, [:node, :task], unique: false
  end
end