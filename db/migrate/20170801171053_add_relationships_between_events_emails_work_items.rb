class AddRelationshipsBetweenEventsEmailsWorkItems < ActiveRecord::Migration[5.1]
  def change
    create_table :emails_premis_events, id: false do |t|
      t.belongs_to :premis_event, index: true
      t.belongs_to :email, index: true
    end

    create_table :emails_work_items, id: false do |t|
      t.belongs_to :work_item, index: true
      t.belongs_to :email, index: true
    end
  end
end
