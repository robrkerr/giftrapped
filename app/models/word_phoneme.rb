class WordPhoneme < ActiveRecord::Base
  belongs_to :word
  belongs_to :phoneme
end
