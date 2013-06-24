class Word < ActiveRecord::Base
  has_many :word_phonemes, :dependent => :delete_all, :order => "vc_block ASC"
  has_many :word_lexemes
  validates :name, :presence => true
  
  def phonemes
    word_phonemes.map { |block| block.phonemes }.flatten
  end

  def phonetic_string
    word_phonemes.map { |block| block.phoneme_string }.join(" - ")
  end

  # def phoneme_types
  #   word_phonemes.map(&:type)
  # end
  
  # def phoneme_string
  #   word_phonemes.map(&:name)
  # end

  # def full_phoneme_names
  #   word_phonemes.map(&:full_name)
  # end
  
  # def num_phonemes
  #   word_phonemes.count
  # end

  def num_phoneme_blocks
    word_phonemes.count
  end

  def num_syllables
    word_phonemes.select { |ph| ph.v_stress != 3 }.length
  end

  def lexemes
    word_lexemes.map { |e| e.lexeme }
  end

  def has_phoneme_block block, index, reverse=false
    return false unless index < num_phoneme_blocks
    wps = reverse ? word_phonemes : word_phonemes.reverse
    wps[index].phoneme_ids == block.phoneme_ids
  end

  # def position_of_last_stressed_vowel reverse=false
  #   stressed = word_phonemes.select { |e| (e.v_stress==1) || (e.v_stress==2) }
  #   reverse ? stressed.first.position : stressed.last.r_position
  # end
end

