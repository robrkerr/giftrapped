class QueriesController < ApplicationController
  
  def create
  	@query = Query.new params[:query]
    respond_to do |format|
    	flash[:alert] = @query.errors.full_messages.to_sentence unless @query.valid?
    	format.html { redirect_to query_path(@query.params) }
    end
  end
  
  def show
  	@query = Query.new params
    @title_word = @query.text if @query.word
    respond_to do |format|
      if (params[:dictionary]!="1") && (!params.has_key?(:id)) && (@query.id)
        format.html { redirect_to query_path(@query.params) }
      else
        format.html # show.html.erb
      end
      format.json { render :json => @query.auto_complete(5).to_json }
    end
  end

end
