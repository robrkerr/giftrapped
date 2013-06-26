class Word < ActiveRecord::Base
  has_many :word_lexemes
  validates :name, :presence => true

end

