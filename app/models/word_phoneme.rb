class WordPhoneme < ActiveRecord::Base
  belongs_to :word
  belongs_to :phoneme

  def full_name
    name + stress_vowel_only
  end
  
  def stress_vowel_only
    (type=="vowel") ? v_stress.to_s : ""
  end

  def type
  	phoneme.ptype
  end

  def name
  	phoneme.name
  end
end
