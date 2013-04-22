class QueriesController < ApplicationController
  
  def create
  	text = params[:query][:text].downcase.split(" ").last.split("-").last
  	get_params = params[:query].slice(:first_phoneme,:num_syllables)
    get_params.select! { |k,v| v && v!="" }
    word = find_words_by_name text
    respond_to do |format|
      if word.length > 1
      	flash[:alert] = "Please select a pronouncation."
      	get_params[:word] = text
      	format.html { redirect_to query_path(get_params) }
      elsif word.length > 0
      	get_params[:id] = word.first.id
        format.html { redirect_to query_path(get_params) }
      else
        flash[:alert] = "The word you entered doesn't match any we know of."
        format.html { redirect_to query_path }
      end
    end
  end
  
  def show
  	@phonemes = get_different_phonemes
  	@ns_value = params[:num_syllables] || ""
  	@fp_value = params[:first_phoneme] || ""
  	@query = Query.new
  	if params[:id]
  		@word = Word.find(params[:id].to_i)
  		@query.text = @word.name
  		words = run_query @word
  		@words_to_show = words[0..12]
    elsif params[:word]
    	@words_to_show = find_words_by_name params[:word]
    	@query.text = @words_to_show.first.name
			standard_params = params.slice(:first_phoneme,:num_syllables)
		  standard_params.select! { |k,v| v && v!="" }
		  @get_params = []
			@words_to_show.each { |word| 
				@get_params << standard_params.merge({:id => word.id})
			}
    end
    respond_to do |format|
      format.html # show.html.erb
    end
  end

private

  def run_query word
  	words = []
    n = word.split_by_vowels.length
    emcompassing_words = word.words_sharing_phonemes_from_last_vowel(n-1)
    emcompassing_words, same_words = emcompassing_words.partition { |w| w.num_phonemes != @word.num_phonemes }
    words = words | emcompassing_words
    (n-2).downto(0) { |i| 
      words = words | word.words_sharing_phonemes_from_last_vowel(i)
    }
    words -= same_words
    if params[:num_syllables] && (params[:num_syllables] != "")
      words = words & words_with_n_syllables(params[:num_syllables].to_i)
    end
    if params[:first_phoneme] && (params[:first_phoneme] != "")
      words = words & words_beginning_with(params[:first_phoneme])
    end
    return words
  end

  def find_words_by_name name
    return Word.find(:all, :conditions => {:name => name})
  end

  def get_different_phonemes
    sql = "select distinct(name) from phonemes order by name asc"
    return Phoneme.find_by_sql(sql)
  end

  def words_with_n_syllables n
    sql_string = "select words.* from words, word_phonemes, phonemes"
    sql_string << " where words.id = word_phonemes.word_id"
    sql_string << " and phonemes.id = word_phonemes.phoneme_id"
    sql_string << " and phonemes.ptype = 'vowel'"
    sql_string << " group by words.id having count(*) = #{n}"
    return Word.find_by_sql(sql_string)
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
    return Word.find_by_sql(sql_string)
  end
end
