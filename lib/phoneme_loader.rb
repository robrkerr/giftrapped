class PhonemeLoader
  def self.get_phonemes
    self.phonemes_without_stresses.map { |p| 
      if p[:ptype] == "vowel"
        [0,1,2].map { |i| p.merge({:stress => i})}
      else
        p.merge({:stress => 0})
      end
    }
  end

  private

  def self.phonemes_without_stresses
    [{:name => "aa", :ptype => "vowel"},
     {:name => "ae", :ptype => "vowel"},
     {:name => "ah", :ptype => "vowel"},
     {:name => "ao", :ptype => "vowel"},
     {:name => "aw", :ptype => "vowel"},
     {:name => "ay", :ptype => "vowel"},
     {:name => "b",  :ptype => "stop"},
     {:name => "ch", :ptype => "affricate"},
     {:name => "d",  :ptype => "stop"},
     {:name => "dh", :ptype => "fricative"},
     {:name => "eh", :ptype => "vowel"},
     {:name => "er", :ptype => "vowel"},
     {:name => "ey", :ptype => "vowel"},
     {:name => "f",  :ptype => "fricative"},
     {:name => "g",  :ptype => "stop"},
     {:name => "hh", :ptype => "aspirate"},
     {:name => "ih", :ptype => "vowel"},
     {:name => "iy", :ptype => "vowel"},
     {:name => "jh", :ptype => "affricate"},
     {:name => "k",  :ptype => "stop"},
     {:name => "l",  :ptype => "liquid"},
     {:name => "m",  :ptype => "nasal"},
     {:name => "n",  :ptype => "nasal"},
     {:name => "ng", :ptype => "nasal"},
     {:name => "ow", :ptype => "vowel"},
     {:name => "oy", :ptype => "vowel"},
     {:name => "p",  :ptype => "stop"},
     {:name => "r",  :ptype => "liquid"},
     {:name => "s",  :ptype => "fricative"},
     {:name => "sh", :ptype => "fricative"},
     {:name => "t",  :ptype => "stop"},
     {:name => "th", :ptype => "fricative"},
     {:name => "uh", :ptype => "vowel"},
     {:name => "uw", :ptype => "vowel"},
     {:name => "v",  :ptype => "fricative"},
     {:name => "w",  :ptype => "semivowel"},
     {:name => "y",  :ptype => "semivowel"},
     {:name => "z",  :ptype => "fricative"},
     {:name => "zh", :ptype => "fricative"}]
  end
end