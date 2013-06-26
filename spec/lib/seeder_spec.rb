require 'spec_helper'
require 'seeder'
require 'phoneme_loader'

describe Seeder do
	it "can enter a single phoneme into the phoneme table" do
		seeder = Seeder.new false
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
		phonemes = [{:name => "aa", :phoneme_type => "vowel"},
								{:name => "n",  :phoneme_type => "nasal"}]
		seeder.seed_phonemes phonemes
		Phoneme.count.should eql(2)
	end
end

describe Seeder do
	it "can enter the full set of phonemes into the phoneme tables" do
		seeder = Seeder.new false
		loader = PhonemeLoader.new
		seeder.seed_phonemes loader.get_phoneme_data
		Phoneme.count.should eql(39)
	end
end

describe Seeder do
	it "can enter a phonetic word into the word and word_phonemes tables" do
		seeder = Seeder.new false
		loader = PhonemeLoader.new
		seeder.seed_phonemes loader.get_phoneme_data
		syllables = [{:onset => ["jh"], :nucleus => ["eh"], :coda => ["s"], :stress => 1},
					 			 {:onset => ["t"],  :nucleus => ["er"], :coda => [],    :stress => 0}]
		words = [{:name => "jester", :syllables => syllables}]
		seeder.seed_words words, 0
		Word.count.should eql(1)
		Word.first.name.should eql("jester")
		Pronunciation.count.should eql(1)
		Pronunciation.first.label.should eql("jh-eh1-s-t-er0")
		WordPronunciation.count.should eql(1)
		WordPronunciation.first.source.should eql(0)
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
		loader = PhonemeLoader.new
		seeder.seed_phonemes loader.get_phoneme_data
		syllables = [{:onset => ["jh"], :nucleus => ["eh"], :coda => ["s"], :stress => 1},
					 			 {:onset => ["t"],  :nucleus => ["er"], :coda => [],    :stress => 0}]
		words = [{:name => "jester", :syllables => syllables}]
		seeder.seed_words words, 0
		should satisfy { Word.count == 1 }
		lexemes = [{:word_class => "noun", :gloss => "jester meaning1"},
							 {:word_class => "verb", :gloss => "jester meaning2"}]
		word_lexemes = [{:word => "jester", :lexemes => lexemes}]
		seeder.seed_lexemes word_lexemes, 0
		Lexeme.count.should eql(2)
		WordLexeme.count.should eql(2)
		Word.first.name.should eql("jester")
		lexeme_records = Lexeme.order(:word_class).all
		lexeme_records[0].word_class.should eql("noun")
		lexeme_records[0].gloss.should eql("jester meaning1")
		lexeme_records[1].word_class.should eql("verb")
		lexeme_records[1].gloss.should eql("jester meaning2")
		word_id = Word.first.id
		lexeme_ids = lexeme_records.map { |lex| lex.id }.sort
		word_lexemes_records = WordLexeme.order(:lexeme_id).all
		word_lexemes_records[0].word_id.should eql(word_id)
		word_lexemes_records[0].lexeme_id.should eql(lexeme_ids[0])
		word_lexemes_records[0].source.should eql(0)
		word_lexemes_records[1].word_id.should eql(word_id)
		word_lexemes_records[1].lexeme_id.should eql(lexeme_ids[1])
		word_lexemes_records[1].source.should eql(0)
	end
end

describe Seeder do
	it "can add existing lexemes to words related to existing words with those lexemes" do
		seeder = Seeder.new false
		loader = PhonemeLoader.new
		seeder.seed_phonemes loader.get_phoneme_data
		syllables1 = [{:onset => ["jh"], :nucleus => ["eh"], :coda => ["s"], :stress => 1},
					 		 	  {:onset => ["t"],  :nucleus => ["er"], :coda => [],    :stress => 0}]
		syllables2 = [{:onset => ["jh"], :nucleus => ["ow"], :coda => ["k"], :stress => 1},
					 			  {:onset => [],     :nucleus => ["er"], :coda => [],    :stress => 0}]
		words = [{:name => "jester", :syllables => syllables1},
						 {:name => "joker",  :syllables => syllables2}]
		seeder.seed_words words, 0
		lexemes = [{:word_class => "noun", :gloss => "jester meaning1"},
							 {:word_class => "verb", :gloss => "jester meaning2"}]
		word_lexemes = [{:word => "jester", :lexemes => lexemes}]
		seeder.seed_lexemes word_lexemes, 0
		related_words = {"jester" => ["joker"]}
		seeder.seed_extra_word_lexemes related_words, 0
		Word.count.should eql(2)
		Lexeme.count.should eql(2)
		WordLexeme.count.should eql(4)
		lexeme_records = Lexeme.order(:id).all
		word_records = Word.order(:id).all
		word_lexemes_records = WordLexeme.order([:word_id,:lexeme_id]).all
		word_lexemes_records[0].word_id.should eql(word_records[0].id)
		word_lexemes_records[0].lexeme_id.should eql(lexeme_records[0].id)
		word_lexemes_records[0].source.should eql(0)
		word_lexemes_records[1].word_id.should eql(word_records[0].id)
		word_lexemes_records[1].lexeme_id.should eql(lexeme_records[1].id)
		word_lexemes_records[1].source.should eql(0)
		word_lexemes_records[2].word_id.should eql(word_records[1].id)
		word_lexemes_records[2].lexeme_id.should eql(lexeme_records[0].id)
		word_lexemes_records[2].source.should eql(0)
		word_lexemes_records[3].word_id.should eql(word_records[1].id)
		word_lexemes_records[3].lexeme_id.should eql(lexeme_records[1].id)
		word_lexemes_records[3].source.should eql(0)
	end
end

