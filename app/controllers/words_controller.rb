class WordsController < ApplicationController
  
  def new
  	@title_word = params[:text]
    respond_to do |format|
      format.html
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

end
