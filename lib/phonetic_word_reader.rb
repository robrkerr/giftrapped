class PhoneticWordReader
  def self.read_words filename
    words = []
    file = File.new(filename,"r")
    while (line = file.gets)
      line.downcase!
      next unless line[%r/^[a-z]/]
      next if line[%r/[0-9]/]
      line = line.chomp.split(" ")
      word = line[0].sub(%r/[0-9]/,"").sub(%r/\(\)/,"")
      phonemes = line[1..-1]
      phonemes.map!{ |ph| 
        simple = ph.sub(%r/[0-9]/,"")
        stress = ph.sub(%r/[a-z]+/,"").to_i
        [simple, stress]
      }
      words << {:name => word, :phonemes => phonemes}
    end
    file.close
    words
  end
end
