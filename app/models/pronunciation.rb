class Pronunciation < ActiveRecord::Base
  has_many :syllables, :order => 'position ASC'
  validates :label, :presence => true
  
end

