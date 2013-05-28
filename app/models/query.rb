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
  	@id ? run_query : possible_words
  end

  def params_for_each_option
		words_to_show.map { |word| optional_params.merge({:id => word.id}) }
  end

  def word
  	valid? ? possible_words.first : nil
  end

  def run_query
    return nil unless valid?
    scope = filter_by_first_phoneme filter_by_num_syllables(WordPhoneme)
    matches_any = word.word_phonemes.reverse.each_with_index.map { |wp, i| 
      "(r_position = #{i} AND phoneme_id = #{wp.phoneme.id})"
    }.join(" or ")
    match_strength = "sum(2 ^ (-r_position-1)) AS match_strength"
    results = scope.select([:word_id, match_strength]).
      where(matches_any).
      where("word_id != ?", word.id).
      group(:word_id).
      order("match_strength DESC").
      limit(13)
    min_strength = (word.phoneme_types.last=="vowel") ? 0.5 : 0.75
    results.select { |e| 
      e.attributes["match_strength"].to_f >= min_strength
    }.map { |e| Word.find(e.word_id) }
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

  def filter_by_first_phoneme scope
    if @first_phoneme.present?
      ph_id = Phoneme.where(:name => @first_phoneme).first.id
      filtered_words = <<-SQL
        INNER JOIN (SELECT word_id AS filtered_word_id FROM word_phonemes
          WHERE position = 0 AND phoneme_id = #{ph_id})
        AS fw1 ON fw1.filtered_word_id = word_id
      SQL
      scope.joins(filtered_words)
    else
      scope
    end
  end

  def filter_by_num_syllables scope
    if @num_syllables.present?
      filtered_words = <<-SQL
        INNER JOIN (SELECT word_id AS filtered_word_id 
          FROM word_phonemes WHERE v_stress < 3 GROUP BY filtered_word_id 
          HAVING count(1) = #{@num_syllables})
        AS fw2 ON fw2.filtered_word_id = word_id
      SQL
      scope.joins(filtered_words)
    else
      scope
    end
  end

end
