require 'spec_helper'
require 'seeder'
require 'phoneme_loader'

describe Seeder do
	it "can enter a single phoneme into the phoneme table" do
		seeder = Seeder.new false
		seeder.clear_phonemes
		seeder.seed_phonemes [{:name => "aa", :ptype => "vowel", :stress => 1}]
		should satisfy { Phoneme.count == 1 }
		phoneme = Phoneme.all.first
		should satisfy { phoneme.name == "aa" }
		should satisfy { phoneme.ptype == "vowel" }
		should satisfy { phoneme.stress == 1 }
	end
end

describe Seeder do
	it "can enter multiple phonemes into the phoneme table" do
		seeder = Seeder.new false
		seeder.clear_phonemes
		phonemes = [{:name => "aa", :ptype => "vowel", :stress => 1},
								{:name => "n",  :ptype => "nasal", :stress => 0}]
		seeder.seed_phonemes phonemes
		should satisfy { Phoneme.count == 2 }
	end
end

describe Seeder do
	it "can enter the full set of phonemes into the phoneme tables" do
		seeder = Seeder.new false
		seeder.clear_phonemes
		seeder.seed_phonemes PhonemeLoader.get_phonemes
		should satisfy { Phoneme.count == 69 }
	end
end

describe Seeder do
	it "can enter a phonetic word into the word and word_phonemes tables" do
		seeder = Seeder.new false
		seeder.clear_phonemes
		seeder.seed_phonemes PhonemeLoader.get_phonemes
		words = [{:name => "wordy", :phonemes => [["w",0],["aa",1]]}]
		seeder.seed_words words
		should satisfy { Word.count == 1 }
		should satisfy { WordPhoneme.count == 2 }
		word = Word.all.first
		should satisfy { word.name == "wordy" }
		phonemes = word.phonemes
		should satisfy { phonemes[0].name == "w" }
		should satisfy { phonemes[0].ptype == "semivowel" }
		should satisfy { phonemes[0].stress == 0 }
		should satisfy { phonemes[1].name == "aa" }
		should satisfy { phonemes[1].ptype == "vowel" }
		should satisfy { phonemes[1].stress == 1 }
	end
end

# seeder.seed_words 'data/cmudict.0.7a.partial'
# 		p Word.count
# 		should satisfy { Word.count == 46 } 

