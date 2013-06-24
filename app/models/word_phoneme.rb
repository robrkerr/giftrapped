class WordPhoneme < ActiveRecord::Base
  belongs_to :word

  def phoneme_string
    phonemes.map { |ph| ph.name }.join(" - ") + stress_vowel_only
  end
  
  def stress_vowel_only
    is_vowel ? v_stress.to_s : ""
  end

  def is_vowel
    v_stress!=3
  end

  def phonemes
    phoneme_ids.map { |id| Phoneme.find(id) }
  end

end
