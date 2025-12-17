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

ActiveRecord::Schema[8.1].define(version: 2025_12_17_022209) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "keymaps", force: :cascade do |t|
    t.string "character", null: false
    t.datetime "created_at", null: false
    t.string "key_position", null: false
    t.integer "layer", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "layer", "key_position"], name: "index_keymaps_on_user_id_and_layer_and_key_position", unique: true
    t.index ["user_id"], name: "index_keymaps_on_user_id"
  end

  create_table "typing_sessions", force: :cascade do |t|
    t.decimal "accuracy", precision: 5, scale: 2
    t.string "category"
    t.datetime "completed_at"
    t.integer "correct_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "duration_seconds"
    t.string "lesson_id"
    t.string "lesson_name"
    t.integer "mistake_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "word_count", default: 0, null: false
    t.index ["user_id", "completed_at"], name: "index_typing_sessions_on_user_id_and_completed_at", order: { completed_at: :desc }
    t.index ["user_id", "created_at"], name: "index_typing_sessions_on_user_id_and_created_at", order: { created_at: :desc }
    t.index ["user_id"], name: "index_typing_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", limit: 254, null: false
    t.string "google_uid", null: false
    t.integer "history_limit", default: 50, null: false
    t.string "icon_url", limit: 4096
    t.string "name", limit: 30, null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "keymaps", "users"
  add_foreign_key "typing_sessions", "users"
end
