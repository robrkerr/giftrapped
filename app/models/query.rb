require 'word_matcher'

class Query
	include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

	attr_accessor :word, :id, :text, :first_onset, :num_syllables
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
		@first_onset = params[:first_onset] || ""
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
      @word = Spelling.where(:label => @text).try(&:first).try(&:words).try(&:first) || nil
      @id = @word.id if @word
		end
	end

  def parse_text text
    # text.downcase.split(" ").last.split("-").last
    text.downcase.split(" ").last
  end

  def persisted?
    false
  end

  def auto_complete number
    return [] unless @term
    words = Spelling.where("label LIKE ?", "#{@term}%").map { |sp| sp.words }.flatten[0..(number-1)]
    words.map { |w| {
        :label => w.name, 
        :phonetic_label => w.pronunciation.label,
        :num_syllables => w.num_syllables,
        :id => w.id
      }
    }
  end

  def dictionary_results text
    results = Spelling.where(label: text).first.words
    results.map { |word| { primary_word: word, other_words: [] } }
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
  		hash[:first_onset] = @first_onset if @first_onset.present?
  		hash[:num_syllables] = @num_syllables if @num_syllables.present?
      hash[:word_type] = @word_type if @word_type.present?
      hash[:reverse] = @reverse if @reverse.present? && @reverse == "1"
      hash[:perfect] = @perfect if @perfect.present? && @perfect == "1"
  	end
  	hash
  end

  def params_for_each_option
		words_to_show.map { |word| optional_params.merge({:id => word[:primary_word].id}) }
  end

  def words_to_show
    return [] unless valid?
    return dictionary_results(@word.name) if (@dictionary=="1")
    run_query
  end

  def run_query
    scope = filter_by_first_onset filter_by_num_syllables(Syllable)
    results = WordMatcher.find_rhymes @word.pronunciation, scope, @number_of_results
    results.map { |pron| { primary_word: pron.words.first, other_words: pron.words[1..-1] } }
  end

  def onset_filter_options 
    onsets = Segment.select([:id,:label]).where(segment_type: 0).order(:label)
    labels = onsets.map(&:label)
    vals = onsets.map(&:id)
		labels.zip(vals)
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

  def filter_by_first_onset scope
    if @first_onset.present?
      filtered_pronunciations = <<-SQL
        INNER JOIN (SELECT pronunciation_id AS filtered_pronunciation_id 
          FROM syllables 
          WHERE position = 0 AND onset_id = #{@first_onset})
        AS fw1 ON fw1.filtered_pronunciation_id = syllables.pronunciation_id
      SQL
      scope.joins(filtered_pronunciations)
    else
      scope
    end
  end

  def filter_by_num_syllables scope
    if @num_syllables.present?
      filtered_pronunciations = <<-SQL
        INNER JOIN (SELECT pronunciation_id AS filtered_pronunciation_id
          FROM syllables GROUP BY pronunciation_id 
          HAVING count(1) = #{@num_syllables})
        AS fw2 ON fw2.filtered_pronunciation_id = syllables.pronunciation_id
      SQL
      scope.joins(filtered_pronunciations)
    else
      scope
    end
  end

end
