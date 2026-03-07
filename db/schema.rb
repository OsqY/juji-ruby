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

ActiveRecord::Schema[8.1].define(version: 2026_03_07_143000) do
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

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "solid_cache_tables", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "budgets", "users"
  add_foreign_key "daily_reports", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "transactions", "users"
end
