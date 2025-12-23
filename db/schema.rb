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

ActiveRecord::Schema[8.1].define(version: 2025_12_23_202059) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "display_order", default: 0, null: false
    t.string "name", limit: 50, null: false
    t.boolean "premium", default: false, null: false
    t.boolean "published", default: true, null: false
    t.boolean "requires_login", default: false, null: false
    t.string "tab", default: "basics", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["tab"], name: "index_categories_on_tab"
  end

  create_table "keymap_sets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "forked_from_id"
    t.boolean "is_public", default: false, null: false
    t.string "name", limit: 50, null: false
    t.string "slug", limit: 50, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["slug"], name: "index_keymap_sets_on_slug"
    t.index ["user_id", "name"], name: "index_keymap_sets_on_user_id_and_name"
    t.index ["user_id", "slug"], name: "index_keymap_sets_on_user_id_and_slug", unique: true
    t.index ["user_id"], name: "index_keymap_sets_on_user_id"
  end

  create_table "keymaps", force: :cascade do |t|
    t.string "character", null: false
    t.datetime "created_at", null: false
    t.string "key_position", null: false
    t.bigint "keymap_set_id", null: false
    t.integer "layer", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["keymap_set_id", "layer", "key_position"], name: "index_keymaps_on_keymap_set_and_layer_and_position", unique: true
    t.index ["keymap_set_id"], name: "index_keymaps_on_keymap_set_id"
    t.index ["user_id"], name: "index_keymaps_on_user_id"
  end

  create_table "lesson_records", force: :cascade do |t|
    t.decimal "accuracy", precision: 5, scale: 2
    t.string "category"
    t.datetime "completed_at"
    t.integer "correct_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "duration_seconds"
    t.string "grade", limit: 20
    t.string "lesson_id"
    t.string "lesson_name"
    t.integer "mistake_count", default: 0, null: false
    t.integer "typed_chars"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "word_count", default: 0, null: false
    t.integer "wpm"
    t.index ["user_id", "completed_at"], name: "index_lesson_records_on_user_id_and_completed_at", order: { completed_at: :desc }
    t.index ["user_id", "created_at"], name: "index_lesson_records_on_user_id_and_created_at", order: { created_at: :desc }
    t.index ["user_id"], name: "index_lesson_records_on_user_id"
  end

  create_table "lessons", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.integer "count", default: 20, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_public", default: false, null: false
    t.jsonb "items", default: [], null: false
    t.string "name", limit: 100, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["category_id"], name: "index_lessons_on_category_id"
    t.index ["is_public"], name: "index_lessons_on_is_public"
    t.index ["user_id", "name"], name: "index_lessons_on_user_id_and_name"
    t.index ["user_id"], name: "index_lessons_on_user_id"
  end

  create_table "shares", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "lesson_record_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_record_id"], name: "index_shares_on_lesson_record_id"
    t.index ["token"], name: "index_shares_on_token", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.integer "active_keymap_set_id", null: false
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "email", limit: 254, null: false
    t.string "google_uid", null: false
    t.string "icon_url", limit: 4096
    t.datetime "last_sign_in_at"
    t.string "name", limit: 30, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.datetime "username_changed_at"
    t.index ["active_keymap_set_id"], name: "index_users_on_active_keymap_set_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
    t.index ["last_sign_in_at"], name: "index_users_on_last_sign_in_at"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "keymap_sets", "users"
  add_foreign_key "keymaps", "keymap_sets"
  add_foreign_key "keymaps", "users"
  add_foreign_key "lesson_records", "users"
  add_foreign_key "lessons", "categories"
  add_foreign_key "lessons", "users"
  add_foreign_key "shares", "lesson_records"
  add_foreign_key "users", "keymap_sets", column: "active_keymap_set_id"
end
