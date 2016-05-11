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

ActiveRecord::Schema.define(version: 20160511201658) do

  create_table "checksums", force: :cascade do |t|
    t.string   "algorithm"
    t.string   "datetime"
    t.string   "digest"
    t.integer  "generic_file_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "checksums", ["generic_file_id"], name: "index_checksums_on_generic_file_id"

  create_table "generic_files", force: :cascade do |t|
    t.string   "file_format"
    t.string   "uri"
    t.float    "size"
    t.string   "identifier"
    t.string   "intellectual_object"
    t.integer  "intellectual_object_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "generic_files", ["intellectual_object_id"], name: "index_generic_files_on_intellectual_object_id"

  create_table "institutions", force: :cascade do |t|
    t.string   "name"
    t.string   "brief_name"
    t.string   "identifier"
    t.string   "dpn_uuid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "intellectual_objects", force: :cascade do |t|
    t.string   "title"
    t.text     "description"
    t.string   "identifier"
    t.string   "alt_identifier"
    t.string   "access"
    t.string   "bag_name"
    t.string   "institution"
    t.integer  "institution_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "intellectual_objects", ["institution_id"], name: "index_intellectual_objects_on_institution_id"

  create_table "premis_events", force: :cascade do |t|
    t.string   "event_identifier"
    t.string   "event_type"
    t.text     "event_outcome"
    t.string   "event_date_time"
    t.string   "event_outcome_detail"
    t.string   "event_detail"
    t.string   "event_outcome_information"
    t.string   "event_object"
    t.string   "event_agent"
    t.integer  "intellectual_object_id"
    t.integer  "generic_file_id"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "premis_events", ["generic_file_id"], name: "index_premis_events_on_generic_file_id"
  add_index "premis_events", ["intellectual_object_id"], name: "index_premis_events_on_intellectual_object_id"

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "phone_number"
    t.string   "institution"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "institution_id"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["institution_id"], name: "index_users_on_institution_id"
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

  create_table "work_items", force: :cascade do |t|
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.integer  "intellectual_object_id"
    t.integer  "generic_file_id"
    t.string   "name"
    t.string   "etag"
    t.string   "bucket"
    t.string   "user"
    t.string   "institution"
    t.text     "note",                    limit: 255
    t.string   "action"
    t.string   "stage"
    t.string   "status"
    t.text     "outcome",                 limit: 255
    t.datetime "bag_date"
    t.datetime "date"
    t.boolean  "retry",                               default: false, null: false
    t.boolean  "reviewed",                            default: false
    t.string   "object_identifier"
    t.string   "generic_file_identifier"
    t.text     "state"
    t.string   "node",                    limit: 255
    t.integer  "pid",                                 default: 0
    t.boolean  "needs_admin_review",                  default: false, null: false
  end

  add_index "work_items", ["action"], name: "index_work_items_on_action"
  add_index "work_items", ["etag", "name"], name: "index_work_items_on_etag_and_name"
  add_index "work_items", ["generic_file_id"], name: "index_work_items_on_generic_file_id"
  add_index "work_items", ["institution"], name: "index_work_items_on_institution"
  add_index "work_items", ["intellectual_object_id"], name: "index_work_items_on_intellectual_object_id"
  add_index "work_items", ["stage"], name: "index_work_items_on_stage"
  add_index "work_items", ["status"], name: "index_work_items_on_status"

end
