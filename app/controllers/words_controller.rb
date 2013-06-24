class WordsController < ApplicationController
  
  def new
  	@title_word = params[:text]
    respond_to do |format|
      format.html
      format.json { render :json => autocomplete_phonemes(params[:q]).to_json }
    end
  end

  def create
    # should take raw input and return something that
    # the model can use without any work.
    # phonemes = WordPhonemeList.parse(params[:phoneme_string])



    # @word = Word.create(name: params[:word_name]) 
    # @word = Word.new params[:word_name], params[:phoneme_string]

    @word = Word.where("name = 'dog'").limit(1).first
    respond_to do |format|
      format.html { redirect_to edit_word_path(@word) }
    end
  end

  def edit
  	@word = Word.find(params[:id])
  	@title_word = @word.name
    respond_to do |format|
      format.html
    end
  end

  def update

  end

  def destroy

  end

  private

  def autocomplete_phonemes term
    phonemes_beginning_with(term).map { |ph| ph.autocomplete_format }.flatten
  end

  def phonemes_beginning_with term
    Phoneme.where(["name LIKE ?", term + "%"])
  end

end
