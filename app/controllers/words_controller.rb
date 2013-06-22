class WordsController < ApplicationController
  
  def new
  	@title_word = params[:text]
    respond_to do |format|
      format.html
      format.json { render :json => autocomplete_phonemes(params[:q]).to_json }
    end
  end

  def create

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
