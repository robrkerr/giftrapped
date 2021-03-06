class Word < ActiveRecord::Base
  belongs_to :spelling
  belongs_to :pronunciation
  has_many :word_lexemes
  has_many :lexemes, :through => :word_lexemes
  has_many :syllables, :through => :pronunciation

  def name
  	spelling.label
  end

  def num_syllables
  	syllables.length
  end

  def last_stressed_syllable
    syllables.reverse.rindex { |s| s.stress > 0 }
  end

end
