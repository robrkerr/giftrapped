class Syllable < ActiveRecord::Base
  belongs_to :pronunciation
  belongs_to :onset, class_name: "Segment"
  belongs_to :nucleus, class_name: "Segment"
  belongs_to :coda, class_name: "Segment"
  
end