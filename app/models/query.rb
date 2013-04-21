class Query
	include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

	attr_accessor :word, :first_phoneme, :num_syllables

	def initialize
  end

  def persisted?
    false
  end
end
