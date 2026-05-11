# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_10_070103) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "anonymous_form_questions", force: :cascade do |t|
    t.integer "anonymous_form_id", null: false
    t.datetime "created_at", null: false
    t.text "options_text"
    t.integer "position", default: 0, null: false
    t.string "prompt", null: false
    t.integer "question_type", default: 2, null: false
    t.boolean "required", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["anonymous_form_id"], name: "index_anonymous_form_questions_on_anonymous_form_id"
  end

  create_table "anonymous_form_responses", force: :cascade do |t|
    t.integer "anonymous_form_id", null: false
    t.json "answers", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["anonymous_form_id", "user_id"], name: "index_anonymous_form_responses_on_form_id_and_user_id_unique", unique: true, where: "user_id IS NOT NULL"
    t.index ["anonymous_form_id"], name: "index_anonymous_form_responses_on_anonymous_form_id"
    t.index ["user_id"], name: "index_anonymous_form_responses_on_user_id"
  end

  create_table "anonymous_forms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "response_limit", default: 1, null: false
    t.integer "responses_count", default: 0, null: false
    t.string "title", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["token"], name: "index_anonymous_forms_on_token", unique: true
    t.index ["user_id"], name: "index_anonymous_forms_on_user_id"
  end

  create_table "budgets", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.date "month", null: false
    t.decimal "monthly_limit", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "month", "category"], name: "index_budgets_on_user_id_and_month_and_category", unique: true
    t.index ["user_id"], name: "index_budgets_on_user_id"
  end

  create_table "chat_room_members", force: :cascade do |t|
    t.integer "chat_room_id", null: false
    t.datetime "created_at", null: false
    t.datetime "joined_at", null: false
    t.integer "role", default: 2, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["chat_room_id", "user_id"], name: "index_chat_room_members_on_chat_room_id_and_user_id", unique: true
    t.index ["chat_room_id"], name: "index_chat_room_members_on_chat_room_id"
    t.index ["user_id"], name: "index_chat_room_members_on_user_id"
  end

  create_table "chat_rooms", force: :cascade do |t|
    t.datetime "archived_at"
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "entry_code"
    t.string "name", null: false
    t.integer "owner_id", null: false
    t.integer "room_type", default: 0, null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_chat_rooms_on_owner_id"
    t.index ["room_type"], name: "index_chat_rooms_on_room_type"
    t.index ["token"], name: "index_chat_rooms_on_token", unique: true
  end

  create_table "daily_reports", force: :cascade do |t|
    t.text "additional_details"
    t.text "blockers"
    t.boolean "blockers_resolved", default: false, null: false
    t.datetime "created_at", null: false
    t.date "report_date"
    t.text "today"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "work_title"
    t.string "worked_by"
    t.text "yesterday"
    t.index ["report_date"], name: "index_daily_reports_on_report_date"
    t.index ["user_id"], name: "index_daily_reports_on_user_id"
  end

  create_table "friendships", force: :cascade do |t|
    t.datetime "accepted_at"
    t.integer "addressee_id", null: false
    t.datetime "created_at", null: false
    t.string "invitation_token", null: false
    t.integer "requester_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["addressee_id"], name: "index_friendships_on_addressee_id"
    t.index ["invitation_token"], name: "index_friendships_on_invitation_token", unique: true
    t.index ["requester_id", "addressee_id"], name: "index_friendships_on_requester_id_and_addressee_id", unique: true
    t.index ["requester_id"], name: "index_friendships_on_requester_id"
  end

  create_table "habit_logs", force: :cascade do |t|
    t.boolean "completed", default: false
    t.datetime "created_at", null: false
    t.integer "habit_id", null: false
    t.date "log_date"
    t.datetime "updated_at", null: false
    t.index ["habit_id"], name: "index_habit_logs_on_habit_id"
  end

  create_table "habits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_habits_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "chat_room_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "message_type", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["chat_room_id", "created_at"], name: "index_messages_on_chat_room_id_and_created_at"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "message"
    t.string "notification_type"
    t.datetime "read_at"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "project_tasks", force: :cascade do |t|
    t.boolean "completed", default: false
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_tasks_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.date "target_date"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "shopping_items", force: :cascade do |t|
    t.boolean "bought", default: false
    t.datetime "created_at", null: false
    t.string "name"
    t.string "quantity"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_shopping_items_on_user_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", limit: 1024, null: false
    t.integer "channel_hash", limit: 8, null: false
    t.datetime "created_at", null: false
    t.binary "payload", limit: 536870912, null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.integer "key_hash", limit: 8, null: false
    t.binary "value", null: false
    t.index ["created_at"], name: "index_solid_cache_entries_on_created_at"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "description", null: false
    t.integer "transaction_type", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["date"], name: "index_transactions_on_date"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "whiteboard_collaborators", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "whiteboard_id", null: false
    t.index ["user_id"], name: "index_whiteboard_collaborators_on_user_id"
    t.index ["whiteboard_id", "user_id"], name: "index_whiteboard_collaborators_on_whiteboard_id_and_user_id", unique: true
    t.index ["whiteboard_id"], name: "index_whiteboard_collaborators_on_whiteboard_id"
  end

  create_table "whiteboard_strokes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "stroke_data"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "whiteboard_id", null: false
    t.index ["user_id"], name: "index_whiteboard_strokes_on_user_id"
    t.index ["whiteboard_id"], name: "index_whiteboard_strokes_on_whiteboard_id"
  end

  create_table "whiteboards", force: :cascade do |t|
    t.string "background_color", default: "#FFFFFF"
    t.datetime "created_at", null: false
    t.integer "height", default: 800
    t.string "name"
    t.string "token"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "width", default: 1200
    t.index ["token"], name: "index_whiteboards_on_token", unique: true
    t.index ["user_id"], name: "index_whiteboards_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "anonymous_form_questions", "anonymous_forms"
  add_foreign_key "anonymous_form_responses", "anonymous_forms"
  add_foreign_key "anonymous_form_responses", "users"
  add_foreign_key "anonymous_forms", "users"
  add_foreign_key "budgets", "users"
  add_foreign_key "daily_reports", "users"
  add_foreign_key "habit_logs", "habits"
  add_foreign_key "habits", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "project_tasks", "projects"
  add_foreign_key "projects", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "shopping_items", "users"
  add_foreign_key "transactions", "users"
  add_foreign_key "whiteboard_collaborators", "users"
  add_foreign_key "whiteboard_collaborators", "whiteboards"
  add_foreign_key "whiteboard_strokes", "users"
  add_foreign_key "whiteboard_strokes", "whiteboards"
  add_foreign_key "whiteboards", "users"
end
