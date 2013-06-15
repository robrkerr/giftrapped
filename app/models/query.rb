class Query
	include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

	attr_accessor :word, :id, :text, :first_phoneme, :num_syllables
  attr_accessor :reverse, :word_type, :perfect, :dictionary
	validate :found_a_word

	def found_a_word
		if @word
      true
    else
			errors[:base] << "The word you entered doesn't match any we know of."
			false
		end
	end

	def initialize params = {}
		@first_phoneme = params[:first_phoneme] || ""
		@num_syllables = params[:num_syllables] || ""
		@word_type = params[:word_type] || ""
    @reverse = params[:reverse] || "0"
    @perfect = params[:perfect] || "0"
    @dictionary = params[:dictionary] || "0"
    @term = params[:term] || false
    @number_of_results = 13
    if params[:id].present?
		  @id = params[:id].to_i
      @word = Word.find(@id)
      @text = @word.name
    else
      @text = params[:text].present? ? parse_text(params[:text]) : ""
      @word = Word.where(:name => @text).try(&:first) || nil
      @id = @word.id if @word
		end
	end

  def parse_text text
    text.downcase.split(" ").last.split("-").last
  end

  def persisted?
    false
  end

  def auto_complete
    return [] unless @term
    words = Word.where("name LIKE ?", "#{@term}%").limit(5)
    words.map { |w| {
        :label => w.name, 
        :phonemes => w.full_phoneme_names,
        :reversed_phonemes => w.full_phoneme_names.reverse,
        :num_syllables => w.num_syllables,
        :id => w.id
      }
    }
  end

  def dictionary_results text, number
    Word.where("name = '#{text}'").limit(number)
  end

  def params
  	basic_params optional_params
  end

  def toggle_params
    basic_params({}, true)
  end

  def basic_params hash={}, toggle=false
    if (@dictionary == "1")
      hash[:text] = @text unless @text == ""
      hash[:dictionary] = "1" unless toggle
    elsif toggle
      hash[:text] = @text unless @text == ""
      hash[:dictionary] = "1"
    else
      hash[:text] = @text unless (@id || @text=="")
      hash[:id] = @id
    end
    hash
  end

  def optional_params hash={}
		if valid?
  		hash[:first_phoneme] = @first_phoneme if @first_phoneme.present?
  		hash[:num_syllables] = @num_syllables if @num_syllables.present?
      hash[:reverse] = @reverse if @reverse.present? && @reverse == "1"
      hash[:perfect] = @perfect if @perfect.present? && @perfect == "1"
  	end
  	hash
  end

  def params_for_each_option
		words_to_show.map { |word| optional_params.merge({:id => word.id}) }
  end

  def position_field
    (@reverse=="1") ? "r_position" : "position"
  end

  def r_position_field
    (@reverse=="1") ? "position" : "r_position"
  end

  def words_to_show
    return [] unless valid?
    return dictionary_results(@word.name, @number_of_results) if (@dictionary=="1")
    run_query
  end

  def run_query
    position_of_last_stress = @word.position_of_last_stressed_vowel(@reverse=="1")
    min_strength = (@word.phoneme_types.last=="vowel") ? 0.5 : 0.75
    min_perfect_strength = 1 - 0.5**(position_of_last_stress+1)
    #
    scope = filter_by_first_phoneme filter_by_num_syllables(WordPhoneme)
    wphonemes = (@reverse=="1") ? @word.word_phonemes : @word.word_phonemes.reverse
    #
    matches_any = wphonemes.each_with_index.map { |wp, i| 
      "(#{r_position_field} = #{i} AND phoneme_id = #{wp.phoneme.id})"
    }.join(" or ")
    match_strength = "sum(2 ^ (-#{r_position_field}-1)) AS match_strength"
    is_stressed = "case v_stress when 1 then 1 when 2 then 1 else 0 end"
    is_last_stressed_position = "case #{r_position_field} when #{position_of_last_stress} then 1 else 0 end"
    stress_match = "sum((#{is_last_stressed_position})*(#{is_stressed})) AS stress_match"
    # stress_count = "sum((#{is_stressed})*2^(-#{r_position_field}-1)) AS stress_count"
    perfect = "case ((sum(2 ^ (-#{r_position_field}-1)) >= #{min_perfect_strength}) AND (sum((#{is_last_stressed_position})*(#{is_stressed})) = 1)) when true then 1 else 0 end AS perfect"
    front_match1 = "case #{position_field} when 0 then 1 else 0 end"
    front_match2 = "case #{r_position_field} when #{wphonemes.length-1} then 1 else 0 end"
    identity_status = "sum((#{front_match1}) + (#{front_match2}))"
    #
    results = scope.select([:word_id, match_strength, stress_match, perfect]).
      where(matches_any).
      where("word_id != ?", @id).
      group(:word_id).
      having("#{identity_status} = 0").
      order("perfect DESC, match_strength DESC").
      limit(@number_of_results)
    results.select { |e|
      if (@perfect=="1")
        (e.attributes["match_strength"].to_f >= min_perfect_strength) && (e.attributes["perfect"].to_f == 1)
      else
        (e.attributes["match_strength"].to_f >= min_strength)
      end
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
          WHERE #{position_field} = 0 AND phoneme_id = #{ph_id})
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
