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

ActiveRecord::Schema[7.2].define(version: 2025_07_15_052223) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "character_images", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "expression", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "expression"], name: "index_character_images_on_user_id_and_expression", unique: true
    t.index ["user_id"], name: "index_character_images_on_user_id"
  end

  create_table "practice_attempt_logs", force: :cascade do |t|
    t.bigint "practice_session_log_id", null: false
    t.bigint "practice_exercise_id", null: false
    t.bigint "user_id", null: false
    t.integer "score"
    t.text "feedback_text"
    t.integer "attempt_number"
    t.datetime "attempted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["practice_exercise_id"], name: "index_practice_attempt_logs_on_practice_exercise_id"
    t.index ["practice_session_log_id"], name: "index_practice_attempt_logs_on_practice_session_log_id"
    t.index ["user_id"], name: "index_practice_attempt_logs_on_user_id"
  end

  create_table "practice_exercises", force: :cascade do |t|
    t.string "title", null: false
    t.text "text_content", null: false
    t.string "category"
    t.integer "difficulty_level"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "duration_minutes", default: 1, null: false
    t.boolean "is_for_onboarding", default: false, null: false
    t.index ["is_active", "category"], name: "index_practice_exercises_on_is_active_and_category"
    t.index ["title"], name: "index_practice_exercises_on_title"
  end

  create_table "practice_session_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "total_score"
    t.datetime "session_started_at", null: false
    t.datetime "session_ended_at"
    t.boolean "is_shared_on_sns", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "session_type"
    t.index ["user_id"], name: "index_practice_session_logs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.string "provider"
    t.string "uid"
    t.datetime "terms_agreed_at"
    t.integer "practice_streak_days", default: 0
    t.integer "total_practice_days", default: 0
    t.datetime "discarded_at"
    t.integer "gender", default: 0, null: false
    t.integer "total_practice_sessions_count", default: 0, null: false
    t.integer "onboarding_status", default: 0, null: false
    t.float "baseline_pitch"
    t.float "baseline_tempo"
    t.float "baseline_volume"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "voice_condition_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "phrase_text_snapshot", null: false
    t.datetime "analyzed_at"
    t.float "pitch_value"
    t.float "tempo_value"
    t.float "volume_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "duration_seconds"
    t.text "analysis_error_message"
    t.bigint "practice_session_log_id"
    t.index ["practice_session_log_id"], name: "index_voice_condition_logs_on_practice_session_log_id"
    t.index ["user_id"], name: "index_voice_condition_logs_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "character_images", "users"
  add_foreign_key "practice_attempt_logs", "practice_exercises"
  add_foreign_key "practice_attempt_logs", "practice_session_logs"
  add_foreign_key "practice_attempt_logs", "users"
  add_foreign_key "practice_session_logs", "users"
  add_foreign_key "voice_condition_logs", "practice_session_logs"
  add_foreign_key "voice_condition_logs", "users"
end
