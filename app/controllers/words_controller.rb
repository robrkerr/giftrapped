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
    Phoneme.where(["name LIKE ?", term + "%"]).map { |ph| 
      is_vowel = ph.ptype == "vowel"
      stresses = is_vowel ? [0,1,2] : [3]
      stresses.map { |i| {:label => ph.name + "#{is_vowel ? i : ''}", :stress => i, :type => ph.ptype}}
    }.flatten[0..5]
  end

end
