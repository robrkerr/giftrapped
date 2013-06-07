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
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @query.auto_complete.to_json }
    end
  end

end
