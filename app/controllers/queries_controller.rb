class QueriesController < ApplicationController
  
  def create
  	@query = Query.new params[:query]
  	load_filter_options
    respond_to do |format|
    	flash[:alert] = @query.errors.full_messages.to_sentence unless @query.valid?
    	format.html { redirect_to query_path(@query.params) }
    end
  end
  
  def show
  	@query = Query.new params
  	load_filter_options
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  protected 

  def load_filter_options
  	load_phoneme_filter_options 
  	load_num_syllables_filter_options
  end

  def load_phoneme_filter_options 
  	sql = "select distinct(name) from phonemes order by name asc"
  	opts = [""] + Phoneme.find_by_sql(sql).map(&:name)
		@phoneme_filter_options = opts.zip(opts)
  end

  def load_num_syllables_filter_options
  	labels = ["","1","2","3","4","5","6","7+"]
		vals = ["",1,2,3,4,5,6,7]
		@num_syllables_filter_options = labels.zip(vals)
  end

end
