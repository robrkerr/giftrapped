require 'phonetic_word_reader'

describe PhoneticWordReader do
	it "can read in a text file contains words and their phonemes" do
		filepath = "test.txt"
		text = 
%Q{A42128  EY1 F AO1 R T UW1 W AH1 N T UW1 EY1 T
.POINT  P OY1 N T
BRIGHTLY  B R AY1 T L IY0
JOURNALIST(1)  JH ER1 N AH0 L IH0 S T
VIKING'S  V AY1 K IH0 NG Z
TABOO  T AE0 B UW1
(BEGIN-PARENS  B IH0 G IH1 N P ER0 EH1 N Z}
		File.open(filepath, "w") { |file| file.puts text }
		words = PhoneticWordReader.read_words(filepath)
		words[0][:name].should eql("brightly")
		words[0][:phonemes].should eql(["b","r","ay1","t","l","iy0"])
		words[1][:name].should eql("journalist")
		words[1][:phonemes].should eql(["jh","er1","n","ah0","l","ih0","s","t"])
		words[2][:name].should eql("viking's")
		words[2][:phonemes].should eql(["v","ay1","k","ih0","ng","z"])
		File.delete(filepath)
	end
end