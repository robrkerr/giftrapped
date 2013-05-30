class Word < ActiveRecord::Base
  has_many :word_phonemes, :dependent => :delete_all, :order => "position ASC"
  has_many :word_lexemes
  validates :name, :presence => true
  
  def phoneme_types
    word_phonemes.map(&:type)
  end
  
  def phoneme_names
    word_phonemes.map(&:name)
  end
  
  def num_phonemes
    word_phonemes.count
  end

  def num_syllables
    phoneme_types.select { |p| p == "vowel"}.length
  end

  def lexemes
    word_lexemes.map { |e| e.lexeme }
  end

  def has_phoneme word_phoneme, index
    return false unless index < num_phonemes
    phoneme_names.reverse[index] == word_phoneme.name
  end
end

