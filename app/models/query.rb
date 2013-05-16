class Query
	include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

	attr_accessor :id, :text, :first_phoneme, :num_syllables, :word_type, :perfect
	validate :exactly_one_word

	def exactly_one_word
		case possible_words.length
		when 1
			true
		when 0
			errors[:base] << "The word you entered doesn't match any we know of."
			false
		else
			errors[:base] << "Please select a pronouncation."
			false
		end
	end

	def initialize params = {}
		@first_phoneme = params[:first_phoneme] || ""
		@num_syllables = params[:num_syllables] || ""
		@word_type = params[:word_type] || ""
		@id = params[:id].try(&:to_i)
		if @id
			@text = possible_words.first.name 	
		else
			@text = params[:text].present? ? params[:text].downcase.split(" ").last.split("-").last : ""
		end
	end

  def persisted?
    false
  end

  def possible_words
  	@id ? [Word.find(@id)] : Word.find(:all, :conditions => {:name => word_name})
  end

  def word_name
  	@text.present? ? @text : ""
  end

  def params
  	hash = optional_params
  	hash[:text] = word_name if possible_words.length > 1
  	hash[:id] = possible_words.first.id if possible_words.length == 1
  	hash
  end

  def optional_params
		hash = {}
		if possible_words.length > 0
  		hash[:first_phoneme] = @first_phoneme if @first_phoneme.present?
  		hash[:num_syllables] = @num_syllables if @num_syllables.present?
  	end
  	hash
  end

  def words_to_show
  	@id ? run_query[0..12] : possible_words
  end

  def params_for_each_option
		words_to_show.map { |word| optional_params.merge({:id => word.id}) }
  end

  def word
  	valid? ? possible_words.first : nil
  end

  def run_query
  	return nil unless valid?
    n = word.split_by_vowels.length
    emcompassing_words = word.words_sharing_phonemes_from_last_vowel(n-1)
    emcompassing_words, same_words = emcompassing_words.partition { |w| w.num_phonemes != word.num_phonemes }
    words = [] | emcompassing_words
    (n-2).downto(0) { |i| 
      words = words | word.words_sharing_phonemes_from_last_vowel(i)
    }
    words -= same_words
    words = words & words_with_n_syllables(@num_syllables.to_i) if @num_syllables.present?
    words = words & words_beginning_with(@first_phoneme) if @first_phoneme.present?
    words
  end

  def phoneme_filter_options 
  	sql = "select distinct(name) from phonemes order by name asc"
  	opts = [""] + Phoneme.find_by_sql(sql).map(&:name)
		opts.zip(opts)
  end

  def num_syllables_filter_options
  	labels = ["","1","2","3","4","5","6","7+"]
		vals = ["",1,2,3,4,5,6,7]
		labels.zip(vals)
  end

  def word_type_filter_options
  	opts = ["","noun","adj","adv","verb"]
		opts.zip(opts)
  end

  private

  def words_with_n_syllables n
    sql_string = "select words.* from words, word_phonemes, phonemes"
    sql_string << " where words.id = word_phonemes.word_id"
    sql_string << " and phonemes.id = word_phonemes.phoneme_id"
    sql_string << " and phonemes.ptype = 'vowel'"
    sql_string << " group by words.id having count(*) = #{n}"
    Word.find_by_sql(sql_string)
  end

  def words_beginning_with ph
    sql_first_phoneme = "select word_id, max(wp.order) as max_order from word_phonemes"
    sql_first_phoneme << " as wp group by word_id"
    sql_string = "select words.* from words, word_phonemes, phonemes, "
    sql_string << "(#{sql_first_phoneme}) as first_phonemes"
    sql_string << " where words.id = word_phonemes.word_id"
    sql_string << " and word_phonemes.word_id = first_phonemes.word_id"
    sql_string << " and word_phonemes.phoneme_id = phonemes.id"
    sql_string << " and phonemes.name = '#{ph}'"
    sql_string << " and word_phonemes.order = first_phonemes.max_order"
    Word.find_by_sql(sql_string)
  end
end
