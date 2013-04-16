class WordsController < ApplicationController
  before_filter :new_input, :only => [:show, :index]
  
  def index
    # @words = Word.find(:all, :limit => 9)
    respond_to do |format|
      format.html 
    end
  end
  
  def create
    find_words_by_name(params[:word][:name].downcase)
    respond_to do |format|
      if @word.length > 1
        # maybe do something better here...
        format.html { redirect_to @word.first }
      elsif @word.length > 0
        format.html { redirect_to @word }
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
    # num = 4
    # @words.select! { |w| w.num_syllables == num }
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
end
