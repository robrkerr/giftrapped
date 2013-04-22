
def load_words file_name
  words = []
  word_phonemes = []
  file = File.new(file_name,"r")
  while (line = file.gets)
  	line.downcase!
  	next if !line[%r/^[a-z]/]
  	line = line.chomp.split(" ")
  	word = line[0].sub(%r/[0-9]/,"").sub(%r/\(\)/,"")
  	phonemes = line[1..-1]
  	phonemes.map!{ |ph| 
  	  simple = ph.sub(%r/[0-9]/,"")
  	  stress = ph.sub(%r/[a-z]+/,"").to_i
  	  [simple, stress]
  	}
  	words << word
  	word_phonemes << phonemes
  end
  file.close
  return words, word_phonemes
end
