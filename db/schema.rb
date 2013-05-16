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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130515115343) do

  create_table "lexemes", :force => true do |t|
    t.string   "word"
    t.string   "word_class"
    t.text     "gloss"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "phonemes", :force => true do |t|
    t.string   "name"
    t.integer  "stress"
    t.string   "ptype"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "word_phonemes", :force => true do |t|
    t.integer  "word_id"
    t.integer  "phoneme_id"
    t.integer  "order"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "word_phonemes", ["phoneme_id"], :name => "index_word_phonemes_on_phoneme_id"
  add_index "word_phonemes", ["word_id"], :name => "index_word_phonemes_on_word_id"

  create_table "words", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
