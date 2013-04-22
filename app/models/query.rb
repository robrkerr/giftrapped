class Query
	include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

	attr_accessor :text, :first_phoneme, :num_syllables

	def initialize
  end

  def persisted?
    false
  end
end
