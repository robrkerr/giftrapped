require 'spec_helper'
require 'seeder'
require 'phoneme_loader'

describe Seeder do
	it "can enter a single phoneme into the phoneme table" do
		seeder = Seeder.new false
		seeder.clear_phonemes
		seeder.seed_phonemes [{:name => "aa", :phoneme_type => "vowel"}]
		Phoneme.count.should eql(1)
		phoneme = Phoneme.all.first
		phoneme.name.should eql("aa")
		phoneme.phoneme_type.should eql("vowel")
	end
end

describe Seeder do
	it "can enter multiple phonemes into the phoneme table" do
		seeder = Seeder.new false
		seeder.clear_phonemes
		phonemes = [{:name => "aa", :phoneme_type => "vowel"},
								{:name => "n",  :phoneme_type => "nasal"}]
		seeder.seed_phonemes phonemes
		Phoneme.count.should eql(2)
	end
end

describe Seeder do
	it "can enter the full set of phonemes into the phoneme tables" do
		seeder = Seeder.new false
		seeder.clear_phonemes
		loader = PhonemeLoader.new
		seeder.seed_phonemes loader.get_phoneme_data
		Phoneme.count.should eql(39)
	end
end

describe Seeder do
	it "can enter a phonetic word into the word and word_phonemes tables" do
		seeder = Seeder.new false
		seeder.clear_phonemes
		loader = PhonemeLoader.new
		seeder.seed_phonemes loader.get_phoneme_data
		syllables = [{:onset => ["jh"], :nucleus => ["eh"], :coda => ["s"], :stress => 1},
					 {:onset => ["t"],  :nucleus => ["er"], :coda => [],    :stress => 0}]
		words = [{:name => "jester", :syllables => syllables}]
		seeder.seed_words words
		Word.count.should eql(1)
		Word.first.name.should eql("jester")
		Pronunciation.count.should eql(1)
		Pronunciation.first.label.should eql("jh-eh1-s-t-er0")
		WordPronunciation.count.should eql(1)
		word_id = WordPronunciation.first.word_id
		pronunciation_id = WordPronunciation.first.pronunciation_id
		Word.first.id.should eql(word_id)
		Pronunciation.first.id.should eql(pronunciation_id)
		PronunciationSyllable.count.should eql(2)
		syllable1, syllable2 = PronunciationSyllable.order("position ASC")
		syllable1.pronunciation_id.should eql(pronunciation_id)
		syllable1.position.should eql(0)
		syllable1.r_position.should eql(1)
		syllable1.stress.should eql(1)
		syllable1.label.should eql("jh-eh1-s")
		syllable2.pronunciation_id.should eql(pronunciation_id)
		syllable2.position.should eql(1)
		syllable2.r_position.should eql(0)
		syllable2.stress.should eql(0)
		syllable2.label.should eql("t-er0")
	end
end

describe Seeder do
	it "can enter a word and its lexemes into the word, lexeme and word_lexemes tables" do
		seeder = Seeder.new false
		seeder.clear_phonemes
		loader = PhonemeLoader.new
		seeder.seed_phonemes loader.get_phoneme_data
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
		loader = PhonemeLoader.new
		seeder.seed_phonemes loader.get_phoneme_data
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

