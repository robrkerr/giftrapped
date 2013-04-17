# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require "#{Rails.root}/db/seed_helper.rb"

load "#{Rails.root}/db/phoneme_seed.rb"
seed_timer("Clearing word table... ") {
  Word.delete_all
}
seed_timer("Clearing word-phoneme table... ") {
  WordPhoneme.delete_all
}
`split -a 1 -l 10000 data/cmudict.0.7a data/word_batch_`
Dir[Rails.root + "data/word_batch_*"].each_with_index do |file,i|
  puts "Loading words: Batch #{i+1}"
  seed_words(file)
end
`rm data/word_batch_*`
# seed_words("#{Rails.root}/data/cmudict.0.7a.partial")
# seed_words("#{Rails.root}/data/cmudict.0.7a.10k")
# seed_words("#{Rails.root}/data/cmudict.0.7a")

