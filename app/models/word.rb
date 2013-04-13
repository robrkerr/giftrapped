class Word < ActiveRecord::Base
  has_many :word_phonemes, :dependent => :delete_all, :order => "word_phonemes.order ASC"
  validates :name, :presence => true
  
  def phonemes_snippet
    return phonemes.map { |e| e.full_name }.join(" - ")
  end
  
  def phonemes
    return self.word_phonemes.map { |e| e.phoneme }
  end
  
  def phoneme_types
    return self.phonemes.map { |e| e.ptype }
  end
  
  def phoneme_names
    return self.phonemes.map { |e| e.name }
  end
  
  def num_phonemes
    return self.word_phonemes.length
  end
  
  def vowel_from_end 
    return num_phonemes - phoneme_types.rindex("vowel")
  end
  
  def rhymes_with word
    return word.rhymes_with(self) if (word.phonemes.length > self.phonemes.length)
    if (self.phonemes.length == 1)
      return -1 if self.phoneme_names.first == word.phoneme_names.first
      return 0
    end
    return -1 if (word.phonemes.length > 1) && self.ends_with_word(word)
    vs = self.vowel_from_end
    vw = word.vowel_from_end
    return 0 if (vw != vs)
    return self.ends_with_word(word, vs) ? 1 : 0
  end
  
  def ends_with_word word, n = 0
    if n==0
      n = word.phoneme_names.length
    end
    return (self.phoneme_names[(-n)..(-1)] == word.phoneme_names[(-n)..(-1)])
  end
    
  def num_syllables
    return self.phoneme_types.select { |p| p == "vowel"}.length
  end
  
end

