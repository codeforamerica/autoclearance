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

ActiveRecord::Schema.define(version: 2018_08_16_220855) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "anon_counts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code"
    t.string "section"
    t.string "description"
    t.string "severity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "anon_event_id", null: false
    t.integer "count_number", null: false
    t.index ["anon_event_id"], name: "index_anon_counts_on_anon_event_id"
  end

  create_table "anon_cycles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "anon_rap_sheet_id", null: false
    t.index ["anon_rap_sheet_id"], name: "index_anon_cycles_on_anon_rap_sheet_id"
  end

  create_table "anon_dispositions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "anon_count_id", null: false
    t.string "disposition_type", null: false
    t.string "sentence"
    t.index ["anon_count_id"], name: "index_anon_dispositions_on_anon_count_id"
  end

  create_table "anon_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "agency"
    t.string "event_type", null: false
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "anon_cycle_id", null: false
    t.index ["anon_cycle_id"], name: "index_anon_events_on_anon_cycle_id"
  end

  create_table "anon_rap_sheets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.binary "checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "county", null: false
    t.integer "year_of_birth"
    t.string "sex"
    t.string "race"
    t.index ["checksum"], name: "index_anon_rap_sheets_on_checksum", unique: true
  end

  add_foreign_key "anon_counts", "anon_events"
  add_foreign_key "anon_cycles", "anon_rap_sheets"
  add_foreign_key "anon_dispositions", "anon_counts"
  add_foreign_key "anon_events", "anon_cycles"
end
