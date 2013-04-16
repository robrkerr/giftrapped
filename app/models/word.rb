class Word < ActiveRecord::Base
  has_many :word_phonemes, :dependent => :delete_all, 
              :order => "word_phonemes.order DESC"
  has_many :phonemes, :through => :word_phonemes
  validates :name, :presence => true
  
  def phonemes_snippet
    return phonemes.map { |e| e.full_name }.join(" - ")
  end
  
  def phonemes
    return word_phonemes.map { |e| e.phoneme }
  end
  
  def phoneme_types
    return phonemes.map { |e| e.ptype }
  end
  
  def phoneme_names
    return phonemes.map { |e| e.name }
  end
  
  def num_phonemes
    return word_phonemes.count
  end
  
  def vowel_from_end 
    return num_phonemes - phoneme_types.rindex("vowel")
  end

  def words_sharing_last_phoneme
    last_phoneme_id = word_phonemes.last.phoneme_id
    Word.joins(:word_phonemes).where(
        'word_phonemes.phoneme_id = ? AND word_phonemes.order = 0', 
        last_phoneme_id) - [self]
  end

  def words_sharing_phonemes_from_last_vowel n = 0
    sql_string_1 = "select words.*"
    sql_string_2 = " from words"
    sql_string_3 = " where"
    split_word = self.split_by_vowels.reverse
    num = 0
    0.upto(n) { |k| 
      last_phoneme_ids = split_word[k].map(&:id).reverse
      last_phoneme_ids.each_with_index { |pid,i| sql_string_2 << ", word_phonemes as wp#{i+num}" }
      last_phoneme_ids.each_with_index { |pid,i| 
        sql_string_3 << " and" if (k != 0) || (i != 0)
        sql_string_3 << " words.id = wp#{i+num}.word_id and wp#{i+num}.phoneme_id = #{pid}" 
        sql_string_3 << " and wp#{i+num}.order = #{i+num}"
      }
      num += last_phoneme_ids.length
    }
    return Word.find_by_sql(sql_string_1 + sql_string_2 + sql_string_3)
  end 
  
  def ends_with_word word, n = 0
    n = num_phonemes if n == 0 
    return (phoneme_names[(-n)..(-1)] == word.phoneme_names[(-n)..(-1)])
  end
    
  def num_syllables
    return phoneme_types.select { |p| p == "vowel"}.length
  end

  def split_by_vowels
    n = num_phonemes
    ph = phonemes
    inds = 0.upto(n-1).select { |i| ph[i].ptype == "vowel" }
    if inds.first == 0
      (inds).flatten.zip(inds.drop(1) << n).map { |i1,i2| ph[i1..(i2-1)] }
    else
      ([0] << inds).flatten.zip(inds << n).map { |i1,i2| ph[i1..(i2-1)] }
    end
  end
end

