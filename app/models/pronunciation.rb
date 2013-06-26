class Pronunciation < ActiveRecord::Base
  validates :label, :presence => true
  
end

