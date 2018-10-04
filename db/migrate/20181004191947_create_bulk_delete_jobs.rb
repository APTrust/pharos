class CreateBulkDeleteJobs < ActiveRecord::Migration[5.2]
  def up
    create_table :bulk_delete_jobs do |t|
      t.string :requested_by
      t.string :institutional_approver
      t.string :aptrust_approver
      t.datetime :institutional_approval_at
      t.datetime :aptrust_approval_at
      t.text :note

      t.timestamps
    end

    create_table :bulk_delete_jobs_institutions, id: false do |t|
      t.belongs_to :bulk_delete_job, index: true
      t.belongs_to :institution, index: true
    end

    create_table :bulk_delete_jobs_intellectual_objects, id: false do |t|
      t.belongs_to :bulk_delete_job, index: { name: 'index_bulk_delete_jobs_intellectual_objects_on_bulk_job_id' }
      t.belongs_to :intellectual_object, index: { name: 'index_bulk_delete_jobs_intellectual_objects_on_object_id' }
    end

    create_table :bulk_delete_jobs_generic_files, id: false do |t|
      t.belongs_to :bulk_delete_job, index: true
      t.belongs_to :generic_file, index: true
    end

    create_table :bulk_delete_jobs_emails, id: false do |t|
      t.belongs_to :bulk_delete_job, index: true
      t.belongs_to :email, index: true
    end
  end

  def down
    drop_table :bulk_delete_jobs

    drop_table :bulk_delete_jobs_institutions

    drop_table :bulk_delete_jobs_intellectual_objects

    drop_table :bulk_delete_jobs_generic_files

    drop_table :bulk_delete_jobs_emails
  end
end
