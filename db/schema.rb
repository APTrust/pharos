# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_10_04_203804) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bulk_delete_jobs", force: :cascade do |t|
    t.string "requested_by"
    t.string "institutional_approver"
    t.string "aptrust_approver"
    t.datetime "institutional_approval_at"
    t.datetime "aptrust_approval_at"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "institution_id", null: false
  end

  create_table "bulk_delete_jobs_emails", id: false, force: :cascade do |t|
    t.bigint "bulk_delete_job_id"
    t.bigint "email_id"
    t.index ["bulk_delete_job_id"], name: "index_bulk_delete_jobs_emails_on_bulk_delete_job_id"
    t.index ["email_id"], name: "index_bulk_delete_jobs_emails_on_email_id"
  end

  create_table "bulk_delete_jobs_generic_files", id: false, force: :cascade do |t|
    t.bigint "bulk_delete_job_id"
    t.bigint "generic_file_id"
    t.index ["bulk_delete_job_id"], name: "index_bulk_delete_jobs_generic_files_on_bulk_delete_job_id"
    t.index ["generic_file_id"], name: "index_bulk_delete_jobs_generic_files_on_generic_file_id"
  end

  create_table "bulk_delete_jobs_institutions", id: false, force: :cascade do |t|
    t.bigint "bulk_delete_job_id"
    t.bigint "institution_id"
    t.index ["bulk_delete_job_id"], name: "index_bulk_delete_jobs_institutions_on_bulk_delete_job_id"
    t.index ["institution_id"], name: "index_bulk_delete_jobs_institutions_on_institution_id"
  end

  create_table "bulk_delete_jobs_intellectual_objects", id: false, force: :cascade do |t|
    t.bigint "bulk_delete_job_id"
    t.bigint "intellectual_object_id"
    t.index ["bulk_delete_job_id"], name: "index_bulk_delete_jobs_intellectual_objects_on_bulk_job_id"
    t.index ["intellectual_object_id"], name: "index_bulk_delete_jobs_intellectual_objects_on_object_id"
  end

  create_table "checksums", id: false, force: :cascade do |t|
    t.serial "id", null: false
    t.string "algorithm"
    t.string "datetime"
    t.string "digest"
    t.integer "generic_file_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["generic_file_id"], name: "index_checksums_on_generic_file_id"
  end

  create_table "confirmation_tokens", id: false, force: :cascade do |t|
    t.bigserial "id", null: false
    t.string "token"
    t.integer "intellectual_object_id"
    t.integer "generic_file_id"
    t.integer "institution_id"
  end

  create_table "dpn_bags", id: false, force: :cascade do |t|
    t.bigserial "id", null: false
    t.integer "institution_id"
    t.string "object_identifier"
    t.string "dpn_identifier"
    t.bigint "dpn_size"
    t.string "node_1"
    t.string "node_2"
    t.string "node_3"
    t.datetime "dpn_created_at"
    t.datetime "dpn_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dpn_work_items", id: false, force: :cascade do |t|
    t.serial "id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "remote_node", limit: 20, default: "", null: false
    t.string "task", limit: 40, default: "", null: false
    t.string "identifier", limit: 40, default: "", null: false
    t.datetime "queued_at"
    t.datetime "completed_at"
    t.string "note", limit: 400
    t.text "state"
    t.string "processing_node", limit: 255
    t.integer "pid", default: 0
    t.boolean "retry", default: true, null: false
    t.string "stage"
    t.string "status"
    t.index ["identifier"], name: "index_dpn_work_items_on_identifier"
    t.index ["remote_node", "task"], name: "index_dpn_work_items_on_remote_node_and_task"
  end

  create_table "emails", id: false, force: :cascade do |t|
    t.bigserial "id", null: false
    t.string "email_type"
    t.string "event_identifier"
    t.integer "item_id"
    t.text "email_text"
    t.text "user_list"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "intellectual_object_id"
    t.integer "generic_file_id"
    t.integer "institution_id"
  end

  create_table "emails_generic_files", id: false, force: :cascade do |t|
    t.bigint "generic_file_id"
    t.bigint "email_id"
    t.index ["email_id"], name: "index_emails_generic_files_on_email_id"
    t.index ["generic_file_id"], name: "index_emails_generic_files_on_generic_file_id"
  end

  create_table "emails_intellectual_objects", id: false, force: :cascade do |t|
    t.bigint "intellectual_object_id"
    t.bigint "email_id"
    t.index ["email_id"], name: "index_emails_intellectual_objects_on_email_id"
    t.index ["intellectual_object_id"], name: "index_emails_intellectual_objects_on_intellectual_object_id"
  end

  create_table "emails_premis_events", id: false, force: :cascade do |t|
    t.bigint "premis_event_id"
    t.bigint "email_id"
    t.index ["email_id"], name: "index_emails_premis_events_on_email_id"
    t.index ["premis_event_id"], name: "index_emails_premis_events_on_premis_event_id"
  end

  create_table "emails_work_items", id: false, force: :cascade do |t|
    t.bigint "work_item_id"
    t.bigint "email_id"
    t.index ["email_id"], name: "index_emails_work_items_on_email_id"
    t.index ["work_item_id"], name: "index_emails_work_items_on_work_item_id"
  end

  create_table "generic_files", id: false, force: :cascade do |t|
    t.serial "id", null: false
    t.string "file_format"
    t.string "uri"
    t.bigint "size"
    t.string "identifier"
    t.integer "intellectual_object_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state"
    t.datetime "last_fixity_check", default: "2000-01-01 00:00:00", null: false
    t.text "ingest_state"
    t.integer "institution_id", null: false
    t.string "storage_option", default: "Standard", null: false
    t.index ["created_at"], name: "index_generic_files_on_created_at"
    t.index ["file_format", "state"], name: "index_generic_files_on_file_format_and_state"
    t.index ["file_format"], name: "index_generic_files_on_file_format"
    t.index ["institution_id", "size", "state"], name: "index_generic_files_on_institution_id_and_size_and_state"
    t.index ["institution_id", "state", "file_format"], name: "index_files_on_inst_state_and_format"
    t.index ["institution_id", "state", "updated_at"], name: "index_files_on_inst_state_and_updated"
    t.index ["institution_id", "state"], name: "index_generic_files_on_institution_id_and_state"
    t.index ["institution_id", "updated_at"], name: "index_generic_files_on_institution_id_and_updated_at"
    t.index ["institution_id"], name: "index_generic_files_on_institution_id"
    t.index ["intellectual_object_id", "file_format"], name: "index_generic_files_on_intellectual_object_id_and_file_format"
    t.index ["intellectual_object_id"], name: "index_generic_files_on_intellectual_object_id"
    t.index ["size", "state"], name: "index_generic_files_on_size_and_state"
    t.index ["size"], name: "index_generic_files_on_size"
    t.index ["state", "updated_at"], name: "index_generic_files_on_state_and_updated_at"
    t.index ["state"], name: "index_generic_files_on_state"
    t.index ["updated_at"], name: "index_generic_files_on_updated_at"
  end

  create_table "institutions", id: false, force: :cascade do |t|
    t.serial "id", null: false
    t.string "name"
    t.string "brief_name"
    t.string "identifier"
    t.string "dpn_uuid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state"
    t.string "type"
    t.integer "member_institution_id"
    t.datetime "deactivated_at"
    t.index ["name"], name: "index_institutions_on_name"
  end

  create_table "intellectual_objects", id: false, force: :cascade do |t|
    t.serial "id", null: false
    t.string "title"
    t.text "description"
    t.string "identifier"
    t.string "alt_identifier"
    t.string "access"
    t.string "bag_name"
    t.integer "institution_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state"
    t.string "etag"
    t.string "dpn_uuid"
    t.text "ingest_state"
    t.string "bag_group_identifier", default: "", null: false
    t.string "storage_option", default: "Standard", null: false
    t.index ["access"], name: "index_intellectual_objects_on_access"
    t.index ["bag_name"], name: "index_intellectual_objects_on_bag_name"
    t.index ["created_at"], name: "index_intellectual_objects_on_created_at"
    t.index ["institution_id", "state"], name: "index_intellectual_objects_on_institution_id_and_state"
    t.index ["institution_id"], name: "index_intellectual_objects_on_institution_id"
    t.index ["state"], name: "index_intellectual_objects_on_state"
    t.index ["updated_at"], name: "index_intellectual_objects_on_updated_at"
  end

  create_table "old_passwords", force: :cascade do |t|
    t.string "encrypted_password", null: false
    t.string "password_salt"
    t.string "password_archivable_type", null: false
    t.integer "password_archivable_id", null: false
    t.datetime "created_at"
    t.index ["password_archivable_type", "password_archivable_id"], name: "index_password_archivable"
  end

  create_table "premis_events", id: :serial, force: :cascade do |t|
    t.string "identifier"
    t.string "event_type"
    t.string "date_time"
    t.string "outcome_detail"
    t.string "detail"
    t.string "outcome_information"
    t.string "object"
    t.string "agent"
    t.integer "intellectual_object_id"
    t.integer "generic_file_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "institution_id"
    t.string "outcome"
    t.string "intellectual_object_identifier", default: "", null: false
    t.string "generic_file_identifier", default: "", null: false
    t.string "old_uuid"
    t.index ["date_time"], name: "index_premis_events_on_date_time"
    t.index ["event_type", "outcome"], name: "index_premis_events_on_event_type_and_outcome"
    t.index ["event_type"], name: "index_premis_events_on_event_type"
    t.index ["generic_file_id", "event_type"], name: "index_premis_events_on_generic_file_id_and_event_type"
    t.index ["generic_file_id"], name: "index_premis_events_on_generic_file_id"
    t.index ["generic_file_identifier"], name: "index_premis_events_on_generic_file_identifier"
    t.index ["identifier", "institution_id"], name: "index_premis_events_on_identifier_and_institution_id"
    t.index ["identifier"], name: "index_premis_events_on_identifier", unique: true
    t.index ["institution_id"], name: "index_premis_events_on_institution_id"
    t.index ["intellectual_object_id"], name: "index_premis_events_on_intellectual_object_id"
    t.index ["intellectual_object_identifier"], name: "index_premis_events_on_intellectual_object_identifier"
    t.index ["outcome"], name: "index_premis_events_on_outcome"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles_users", id: false, force: :cascade do |t|
    t.integer "role_id"
    t.integer "user_id"
    t.index ["role_id", "user_id"], name: "index_roles_users_on_role_id_and_user_id"
    t.index ["user_id", "role_id"], name: "index_roles_users_on_user_id_and_role_id"
  end

  create_table "snapshots", force: :cascade do |t|
    t.datetime "audit_date"
    t.integer "institution_id"
    t.bigint "apt_bytes"
    t.decimal "cost"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "snapshot_type"
    t.bigint "cs_bytes"
    t.bigint "go_bytes"
  end

  create_table "usage_samples", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "institution_id"
    t.text "data"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "institution_id"
    t.text "encrypted_api_secret_key"
    t.datetime "password_changed_at"
    t.datetime "deactivated_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["institution_id"], name: "index_users_on_institution_id"
    t.index ["password_changed_at"], name: "index_users_on_password_changed_at"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "work_item_states", id: :serial, force: :cascade do |t|
    t.integer "work_item_id"
    t.string "action", null: false
    t.binary "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "work_items", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "intellectual_object_id"
    t.integer "generic_file_id"
    t.string "name"
    t.string "etag"
    t.string "bucket"
    t.string "user"
    t.text "note"
    t.string "action"
    t.string "stage"
    t.string "status"
    t.text "outcome"
    t.datetime "bag_date"
    t.datetime "date"
    t.boolean "retry", default: false, null: false
    t.string "object_identifier"
    t.string "generic_file_identifier"
    t.string "node", limit: 255
    t.integer "pid", default: 0
    t.boolean "needs_admin_review", default: false, null: false
    t.integer "institution_id"
    t.datetime "queued_at"
    t.bigint "size"
    t.datetime "stage_started_at"
    t.string "aptrust_approver"
    t.string "inst_approver"
    t.index ["action"], name: "index_work_items_on_action"
    t.index ["date"], name: "index_work_items_on_date"
    t.index ["etag", "name"], name: "index_work_items_on_etag_and_name"
    t.index ["generic_file_id"], name: "index_work_items_on_generic_file_id"
    t.index ["institution_id", "date"], name: "index_work_items_on_institution_id_and_date"
    t.index ["institution_id"], name: "index_work_items_on_institution_id"
    t.index ["intellectual_object_id"], name: "index_work_items_on_intellectual_object_id"
    t.index ["stage"], name: "index_work_items_on_stage"
    t.index ["status"], name: "index_work_items_on_status"
  end

end
