require 'spec_helper'
require 'seeder'
require 'phoneme_loader'

describe Seeder do
	it "can enter a single phoneme into the phoneme table" do
		seeder = Seeder.new false
		seeder.clear_phonemes
		seeder.seed_phonemes [{:name => "aa", :ptype => "vowel"}]
		should satisfy { Phoneme.count == 1 }
		phoneme = Phoneme.all.first
		should satisfy { phoneme.name == "aa" }
		should satisfy { phoneme.ptype == "vowel" }
	end
end

describe Seeder do
	it "can enter multiple phonemes into the phoneme table" do
		seeder = Seeder.new false
		seeder.clear_phonemes
		phonemes = [{:name => "aa", :ptype => "vowel"},
								{:name => "n",  :ptype => "nasal"}]
		seeder.seed_phonemes phonemes
		should satisfy { Phoneme.count == 2 }
	end
end

describe Seeder do
	it "can enter the full set of phonemes into the phoneme tables" do
		seeder = Seeder.new false
		seeder.clear_phonemes
		seeder.seed_phonemes PhonemeLoader.get_phonemes
		should satisfy { Phoneme.count == 39 }
	end
end

describe Seeder do
	it "can enter a phonetic word into the word and word_phonemes tables" do
		seeder = Seeder.new false
		seeder.clear_phonemes
		seeder.seed_phonemes PhonemeLoader.get_phonemes
		words = [{:name => "wordy", :phonemes => [["w"],["aa",1],["t"],["hh"]]}]
		seeder.seed_words words
		should satisfy { Word.count == 1 }
		should satisfy { WordPhoneme.count == 4 }
		word = Word.first
		should satisfy { word.name == "wordy" }
		wphonemes = word.word_phonemes
		should satisfy { wphonemes[0].position == 0 }
		should satisfy { wphonemes[0].r_position == 3 }
		should satisfy { wphonemes[0].vc_block == 0 }
		should satisfy { wphonemes[0].v_stress == 3 }
		should satisfy { wphonemes[1].position == 1 }
		should satisfy { wphonemes[1].r_position == 2 }
		should satisfy { wphonemes[1].vc_block == 1 }
		should satisfy { wphonemes[1].v_stress == 1 }
		should satisfy { wphonemes[2].position == 2 }
		should satisfy { wphonemes[2].r_position == 1 }
		should satisfy { wphonemes[2].vc_block == 2 }
		should satisfy { wphonemes[2].v_stress == 3 }
		should satisfy { wphonemes[3].position == 3 }
		should satisfy { wphonemes[3].r_position == 0 }
		should satisfy { wphonemes[3].vc_block == 2 }
		should satisfy { wphonemes[3].v_stress == 3 }
		phoneme_names = word.phoneme_names
		should satisfy { phoneme_names[0] == "w" }
		should satisfy { phoneme_names[1] == "aa" }
		should satisfy { phoneme_names[2] == "t" }
		should satisfy { phoneme_names[3] == "hh" }
		phoneme_types = word.phoneme_types
		should satisfy { phoneme_types[0] == "semivowel" }
		should satisfy { phoneme_types[1] == "vowel" }
		should satisfy { phoneme_types[2] == "stop" }
		should satisfy { phoneme_types[3] == "aspirate" }
	end
end

describe Seeder do
	it "can enter a word and its lexemes into the word, lexeme and word_lexemes tables" do
		seeder = Seeder.new false
		seeder.clear_phonemes
		seeder.seed_phonemes PhonemeLoader.get_phonemes
		words = [{:name => "rabbit", :phonemes => [["r"]]}]
		seeder.seed_words words
		should satisfy { Word.count == 1 }
		seeder.clear_lexemes
		lexemes = [{:lexeme_id => 0, :word_class => "noun", :gloss => "rabbit meaning1"},
							 {:lexeme_id => 1, :word_class => "verb", :gloss => "rabbit meaning2"}]
		word_lexemes = {"rabbit" => [0,1]}
		seeder.seed_lexemes lexemes, word_lexemes
		should satisfy { Lexeme.count == 2 }
		should satisfy { WordLexeme.count == 2 }
		word = Word.first
		should satisfy { word.name == "rabbit" }
		lex = word.lexemes
		should satisfy { lex.length == 2 }
		should satisfy { lex[0].word_class == "noun" }
		should satisfy { lex[0].gloss == "rabbit meaning1" }
		should satisfy { lex[1].word_class == "verb" }
		should satisfy { lex[1].gloss == "rabbit meaning2" }
	end
end

describe Seeder do
	it "can add existing lexemes to words related to existing words with those lexemes" do
		seeder = Seeder.new false
		seeder.clear_phonemes
		seeder.seed_phonemes PhonemeLoader.get_phonemes
		words = [{:name => "rabbit", :phonemes => [["r"]]},
						 {:name => "rabbity", :phonemes => [["r"]]},
						 {:name => "rabbits", :phonemes => [["r"]]}]
		seeder.seed_words words
		should satisfy { Word.count == 3 }
		seeder.clear_lexemes
		lexemes = [{:lexeme_id => 0, :word_class => "noun", :gloss => "rabbit meaning1"},
							 {:lexeme_id => 1, :word_class => "verb", :gloss => "rabbit meaning2"}]
		word_lexemes = {"rabbit" => [0,1]}
		seeder.seed_lexemes lexemes, word_lexemes
		related_words = {"rabbit" => ["rabbits","rabbity"]}
		seeder.seed_extra_word_lexemes related_words
		should satisfy { Lexeme.count == 2 }
		should satisfy { WordLexeme.count == 6 }
		word = Word.where("name = 'rabbits'").first
		should satisfy { word.name == "rabbits" }
		lex = word.lexemes
		should satisfy { lex.length == 2 }
		should satisfy { lex[0].word_class == "noun" }
		should satisfy { lex[0].gloss == "rabbit meaning1" }
		should satisfy { lex[1].word_class == "verb" }
		should satisfy { lex[1].gloss == "rabbit meaning2" }
	end
end
