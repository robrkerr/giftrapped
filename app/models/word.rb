class Word < ActiveRecord::Base
  belongs_to :spelling
  belongs_to :pronunciation
  has_many :lexemes, :through => :word_lexemes

  def name
  	spelling.label
  end

end
