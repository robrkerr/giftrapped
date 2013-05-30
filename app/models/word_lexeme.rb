class WordLexeme < ActiveRecord::Base
  belongs_to :word
  belongs_to :lexeme

  def lexeme
  	lexeme = Lexeme.where("lexeme_id = #{lexeme_id}")
  	(lexeme.length==1) ? lexeme.first : nil
  end
end
