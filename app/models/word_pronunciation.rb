class WordPronunciation < ActiveRecord::Base
  belongs_to :word
  belongs_to :pronunciation

end
