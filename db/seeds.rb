# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require "#{Rails.root}/db/seed_helper.rb"

load "#{Rails.root}/db/phoneme_seed.rb"
# seed_words("#{Rails.root}/data/cmudict.0.7a.partial")
seed_words("#{Rails.root}/data/cmudict.0.7a.10k")
# seed_words("#{Rails.root}/data/cmudict.0.7a")

