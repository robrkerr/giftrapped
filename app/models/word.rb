class Word < ActiveRecord::Base
  has_many :word_phonemes, :dependent => :delete_all, 
              :order => "word_phonemes.order DESC"
  has_many :phonemes, :through => :word_phonemes
  validates :name, :presence => true
  
  def phonemes
    word_phonemes.map(&:phoneme)
  end
  
  def phoneme_types
    phonemes.map(&:ptype)
  end
  
  def phoneme_names
    phonemes.map(&:name)
  end
  
  def num_phonemes
    word_phonemes.count
  end

  def num_syllables
    phoneme_types.select { |p| p == "vowel"}.length
  end

  def words_sharing_phonemes_from_last_vowel n = 0
    sql_string_1 = "select words.*"
    sql_string_2 = " from words"
    sql_string_3 = " where"
    split_word = self.split_by_vowels.reverse
    num = 0
    0.upto(n) { |k| 
      last_phoneme_names = split_word[k].map(&:name).reverse
      last_phoneme_names.each_with_index { |pname,i| 
        sql_string_2 << ", word_phonemes as wp#{i+num}, phonemes as ph#{i+num}" 
      }
      last_phoneme_names.each_with_index { |pname,i| 
        sql_string_3 << " and" if (k != 0) || (i != 0)
        sql_string_3 << " words.id = wp#{i+num}.word_id and wp#{i+num}.phoneme_id = ph#{i+num}.id"
        sql_string_3 << " and wp#{i+num}.order = #{i+num} and ph#{i+num}.name = '#{pname}'"
      }
      num += last_phoneme_names.length
    }
    return Word.find_by_sql(sql_string_1 + sql_string_2 + sql_string_3)
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

