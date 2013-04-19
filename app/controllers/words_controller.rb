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
      @words.select! { |w| w.num_syllables == params[:num_syllables].to_i }
      @ns_value = params[:num_syllables]
    else
      @ns_value = ""
    end
    if params[:first_phoneme] && (params[:first_phoneme] != "")
      @words.select! { |w| w.phonemes[0].name == params[:first_phoneme] }
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
end
