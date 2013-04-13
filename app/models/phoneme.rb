class Phoneme < ActiveRecord::Base
  def full_name
    return name + stress_vowel_only
  end
  
  def stress_vowel_only
    return (ptype=="vowel") ? stress.to_s : ""
  end
end
