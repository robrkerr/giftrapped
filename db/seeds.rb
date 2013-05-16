# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require 'seeder'
require 'phoneme_loader'
require 'phonetic_word_reader'
require 'word_lexeme_reader'

def seed_timer task_msg
  print task_msg
  time = Time.now
  yield
  print "Done. (#{Time.now-time}s)\n"
end

seeder = Seeder.new
seed_timer("Clearing tables... ") {
  seeder.clear_phonemes
  seeder.clear_words
  seeder.clear_lexemes
}
seed_timer("Seeding phonemes... ") {
  seeder.seed_phonemes PhonemeLoader.get_phonemes
}
Dir[Rails.root + "data/wordnet/data.*"].each_with_index do |file,i|
  puts "Loading lexemes: Batch #{i+1}"
  lexemes = []
  seed_timer("  Reading lexemes... ") {
  	lexemes = WordLexemeReader.read_lexemes(file)
  }
  seed_timer("  Populating lexeme table... ") {
  	seeder.seed_lexemes lexemes
  }
end
`split -a 1 -l 10000 data/cmudict.0.7a data/word_batch_`
Dir[Rails.root + "data/word_batch_*"].each_with_index do |file,i|
  puts "Loading words: Batch #{i+1}"
  words = []
  seed_timer("  Reading words... ") {
  	words = PhoneticWordReader.read_words(file)
  }
  seed_timer("  Populating word tables... ") {
  	seeder.seed_words words
  }
end
`rm data/word_batch_*`

