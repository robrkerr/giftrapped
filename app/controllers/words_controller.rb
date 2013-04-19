class WordsController < ApplicationController
  before_filter :new_input, :only => [:show, :index]
  before_filter :get_different_phonemes, :only => [:show, :index]
  
  def index
    respond_to do |format|
      format.html 
    end
  end
  
  def create
    find_words_by_name(params[:name].downcase)
    get_params = params.slice(:first_phoneme,:num_syllables).select { |k,v| v && v!="" }
    respond_to do |format|
      if @word.length > 1
        # maybe do something better here...
        format.html { redirect_to word_path(@word.first, get_params) }
      elsif @word.length > 0
        format.html { redirect_to word_path(@word, get_params) }
      else
        flash[:alert] = "The word you entered doesn't match any we know of."
        format.html { redirect_to words_path }
      end
    end
  end
  
  def show
    @word = Word.find(params[:id])
    @words = []
    n = @word.split_by_vowels.length
    emcompassing_words = @word.words_sharing_phonemes_from_last_vowel(n-1)
    emcompassing_words, same_words = emcompassing_words.partition { |w| w.num_phonemes != @word.num_phonemes }
    @words = @words | emcompassing_words
    (n-2).downto(0) { |i| 
      @words = @words | @word.words_sharing_phonemes_from_last_vowel(i)
    }
    @words -= same_words
    if params[:num_syllables] && (params[:num_syllables] != "")
      @words = @words & words_with_n_syllables(params[:num_syllables].to_i)
      @ns_value = params[:num_syllables]
    else
      @ns_value = ""
    end
    if params[:first_phoneme] && (params[:first_phoneme] != "")
      @words = @words & words_beginning_with(params[:first_phoneme])
      @fp_value = params[:first_phoneme]
    else
      @fp_value = ""
    end
    @words_to_show = @words[0..12]
    respond_to do |format|
      format.html # show.html.erb
    end
  end

private

  def find_words_by_name name
    @word = Word.find(:all, :conditions => {:name => name})
  end
  
  def new_input
    @input = Word.new
  end

  def get_different_phonemes
    @phonemes = Phoneme.find_by_sql("select distinct(name) from phonemes order by name asc")
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
