# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20161116142651) do

  create_table "checksums", force: :cascade do |t|
    t.string   "algorithm"
    t.string   "datetime"
    t.string   "digest"
    t.integer  "generic_file_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "checksums", ["generic_file_id"], name: "index_checksums_on_generic_file_id"

  create_table "dpn_work_items", force: :cascade do |t|
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.string   "remote_node",  limit: 20,        default: "", null: false
    t.string   "task",         limit: 40,        default: "", null: false
    t.string   "identifier",   limit: 40,        default: "", null: false
    t.datetime "queued_at"
    t.datetime "completed_at"
    t.string   "note",         limit: 400
    t.text     "state",        limit: 104857600
  end

  add_index "dpn_work_items", ["identifier"], name: "index_dpn_work_items_on_identifier"
  add_index "dpn_work_items", ["remote_node", "task"], name: "index_dpn_work_items_on_remote_node_and_task"

  create_table "generic_files", force: :cascade do |t|
    t.string   "file_format"
    t.string   "uri"
    t.float    "size"
    t.string   "identifier"
    t.integer  "intellectual_object_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "permissions"
    t.string   "state"
  end

  add_index "generic_files", ["identifier"], name: "index_generic_files_on_identifier", unique: true
  add_index "generic_files", ["intellectual_object_id"], name: "index_generic_files_on_intellectual_object_id"

  create_table "institutions", force: :cascade do |t|
    t.string   "name"
    t.string   "brief_name"
    t.string   "identifier"
    t.string   "dpn_uuid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "state"
  end

  create_table "intellectual_objects", force: :cascade do |t|
    t.string   "title"
    t.text     "description"
    t.string   "identifier"
    t.string   "alt_identifier"
    t.string   "access"
    t.string   "bag_name"
    t.integer  "institution_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "state"
    t.string   "etag"
    t.string   "dpn_uuid"
  end

  add_index "intellectual_objects", ["identifier"], name: "index_intellectual_objects_on_identifier", unique: true
  add_index "intellectual_objects", ["institution_id"], name: "index_intellectual_objects_on_institution_id"

  create_table "premis_events", force: :cascade do |t|
    t.string   "identifier"
    t.string   "event_type"
    t.string   "date_time"
    t.string   "outcome_detail"
    t.string   "detail"
    t.string   "outcome_information"
    t.string   "object"
    t.string   "agent"
    t.integer  "intellectual_object_id"
    t.integer  "generic_file_id"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.string   "outcome"
    t.integer  "institution_id"
    t.string   "intellectual_object_identifier", default: "", null: false
    t.string   "generic_file_identifier",        default: "", null: false
    t.string   "old_uuid"
  end

  add_index "premis_events", ["generic_file_id"], name: "index_premis_events_on_generic_file_id"
  add_index "premis_events", ["identifier"], name: "index_premis_events_on_identifier", unique: true
  add_index "premis_events", ["intellectual_object_id"], name: "index_premis_events_on_intellectual_object_id"

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles_users", id: false, force: :cascade do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "roles_users", ["role_id", "user_id"], name: "index_roles_users_on_role_id_and_user_id"
  add_index "roles_users", ["user_id", "role_id"], name: "index_roles_users_on_user_id_and_role_id"

  create_table "usage_samples", force: :cascade do |t|
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "institution_id"
    t.text     "data"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "phone_number"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "encrypted_password",       default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",            default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "institution_id"
    t.text     "encrypted_api_secret_key"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["institution_id"], name: "index_users_on_institution_id"
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

  create_table "work_item_states", force: :cascade do |t|
    t.integer  "work_item_id"
    t.string   "action",       null: false
    t.binary   "state"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "work_items", force: :cascade do |t|
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.integer  "intellectual_object_id"
    t.integer  "generic_file_id"
    t.string   "name"
    t.string   "etag"
    t.string   "bucket"
    t.string   "user"
    t.text     "note",                    limit: 255
    t.string   "action"
    t.string   "stage"
    t.string   "status"
    t.text     "outcome",                 limit: 255
    t.datetime "bag_date"
    t.datetime "date"
    t.boolean  "retry",                               default: false, null: false
    t.string   "object_identifier"
    t.string   "generic_file_identifier"
    t.string   "node",                    limit: 255
    t.integer  "pid",                                 default: 0
    t.boolean  "needs_admin_review",                  default: false, null: false
    t.integer  "institution_id"
    t.datetime "queued_at"
    t.integer  "work_item_state_id"
    t.integer  "size"
    t.datetime "stage_started_at"
  end

  add_index "work_items", ["action"], name: "index_work_items_on_action"
  add_index "work_items", ["etag", "name"], name: "index_work_items_on_etag_and_name"
  add_index "work_items", ["generic_file_id"], name: "index_work_items_on_generic_file_id"
  add_index "work_items", ["intellectual_object_id"], name: "index_work_items_on_intellectual_object_id"
  add_index "work_items", ["stage"], name: "index_work_items_on_stage"
  add_index "work_items", ["status"], name: "index_work_items_on_status"

end
