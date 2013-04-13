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
    @words = Word.includes(:word_phonemes => :phoneme).all
    @words.sort_by! { |w| -@word.rhymes_with(w) }
    @words = @words[0..16]
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
