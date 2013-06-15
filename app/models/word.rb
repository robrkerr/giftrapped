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

  def full_phoneme_names
    word_phonemes.map(&:full_name)
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

  def has_phoneme word_phoneme, index, reverse=false
    return false unless index < num_phonemes
    names = reverse ? phoneme_names : phoneme_names.reverse
    names[index] == word_phoneme.name
  end

  def position_of_last_stressed_vowel reverse=false
    stressed = word_phonemes.select { |e| (e.v_stress==1) || (e.v_stress==2) }
    reverse ? stressed.first.position : stressed.last.r_position
  end
end

