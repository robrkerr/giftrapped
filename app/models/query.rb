class Query
	include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

	attr_accessor :word, :id, :text, :first_phoneme, :num_syllables
  attr_accessor :reverse, :word_type, :perfect, :dictionary
	validate :found_a_word

	def found_a_word
		if @word
      true
    else
			errors[:base] << "The word you entered doesn't match any we know of."
			false
		end
	end

	def initialize params = {}
		@first_phoneme = params[:first_phoneme] || ""
		@num_syllables = params[:num_syllables] || ""
		@word_type = params[:word_type] || ""
    @reverse = params[:reverse] || "0"
    @perfect = params[:perfect] || "0"
    @dictionary = params[:dictionary] || "0"
    @term = params[:term] || false
    @number_of_results = 13
    if params[:id].present?
		  @id = params[:id].to_i
      @word = Word.find(@id)
      @text = @word.name
    else
      @text = params[:text].present? ? parse_text(params[:text]) : ""
      @word = Word.where(:name => @text).try(&:first) || nil
      @id = @word.id if @word
		end
	end

  def parse_text text
    text.downcase.split(" ").last.split("-").last
  end

  def persisted?
    false
  end

  def auto_complete
    return [] unless @term
    words = Word.where("name LIKE ?", "#{@term}%").limit(5)
    words.map { |w| {
        :label => w.name, 
        :phonetic_label => w.phonetic_string,
        :num_syllables => w.num_syllables,
        :id => w.id
      }
    }
  end

  def dictionary_results text, number
    Word.where("name = '#{text}'").limit(number)
  end

  def params
  	basic_params optional_params
  end

  def toggle_params
    basic_params({}, true)
  end

  def basic_params hash={}, toggle=false
    if (@dictionary == "1")
      hash[:text] = @text unless @text == ""
      hash[:dictionary] = "1" unless toggle
    elsif toggle
      hash[:text] = @text unless @text == ""
      hash[:dictionary] = "1"
    else
      hash[:text] = @text unless (@id || @text=="")
      hash[:id] = @id
    end
    hash
  end

  def optional_params hash={}
		if valid?
  		hash[:first_phoneme] = @first_phoneme if @first_phoneme.present?
  		hash[:num_syllables] = @num_syllables if @num_syllables.present?
      hash[:word_type] = @word_type if @word_type.present?
      hash[:reverse] = @reverse if @reverse.present? && @reverse == "1"
      hash[:perfect] = @perfect if @perfect.present? && @perfect == "1"
  	end
  	hash
  end

  def params_for_each_option
		words_to_show.map { |word| optional_params.merge({:id => word.id}) }
  end

  def vc_block_field
    (@reverse=="1") ? "r_vc_block" : "vc_block"
  end

  def r_vc_block_field
    (@reverse=="1") ? "vc_block" : "r_vc_block"
  end

  def words_to_show
    return [] unless valid?
    return dictionary_results(@word.name, @number_of_results) if (@dictionary=="1")
    run_query
  end

  def run_query
    # position_of_last_stress = @word.position_of_last_stressed_vowel(@reverse=="1")
    min_strength = (@word.word_phonemes.last.is_vowel) ? 0.5 : 0.75
    # min_perfect_strength = 1 - 0.5**(position_of_last_stress+1)
    #
    if @word_type.present?
      word_type_sub_query = "SELECT word_id FROM word_lexemes, lexemes WHERE word_lexemes.lexeme_id = lexemes.lexeme_id AND lexemes.word_class = '#{@word_type}' GROUP BY word_id"
      initial_scope = WordPhoneme.joins("INNER JOIN (#{word_type_sub_query}) AS filtered ON word_phonemes.word_id = filtered.word_id")
    else
      initial_scope = WordPhoneme
    end
    scope = filter_by_first_phoneme filter_by_num_syllables(initial_scope)
    results = scope.joins("INNER JOIN word_phonemes AS this_word 
                           ON this_word.r_vc_block = word_phonemes.r_vc_block 
                           AND this_word.phoneme_ids = word_phonemes.phoneme_ids").
                    where("this_word.word_id = #{@word.id}").
                    group("word_phonemes.word_id").
                    having("sum(2 ^ (-word_phonemes.r_vc_block-1)) >= #{min_strength}").
                    select(["word_phonemes.word_id", 
                            "sum(2 ^ (-word_phonemes.r_vc_block-1)) AS match_strength"]).
                    order("match_strength DESC, word_phonemes.word_id ASC").
                    limit(@number_of_results)
    # if @word.word_phonemes.first.is_vowel
    #   fronts_match = "CASE vc_block = 0 AND r_vc_block = #{@word.num_phoneme_blocks-1} 
    #                   WHEN true THEN 2 ELSE 0 END"
    #   identity_status = "sum(#{fronts_match})"
    # else
    #   front_match1 = "case #{position_field} = 0 AND v_stress = 3 when true then 1 else 0 end"
    #   front_match2 = "case #{r_position_field} when #{wphonemes.length-1} then 1 else 0 end"
    #   identity_status = "sum((#{front_match1}) + (#{front_match2}))"
    # end



    ### CREATE A VIEW / TABLE OF WORD_PHONEME_BLOCKS!!
    ### WINDOW FUNCTIONS!!:     
    # SELECT depname, empno, salary, avg(salary) OVER (PARTITION BY depname) FROM empsalary;

    # <<-SQL
    #   SELECT other_words.word_id, sum(2 ^ (-other_words.r_vc_block-1)) AS match_strength
    #   FROM word_phoneme_blocks AS this_word, word_phoneme_blocks AS other_words
    #   WHERE this_word.r_vc_block = other_words.r_vc_block 
    #     AND this_word.phonemes = other_words.phonemes
    #     AND this_word.word_id = 1816654
    #   GROUP BY other_words.word_id
    #   HAVING sum(2 ^ (-other_words.r_vc_block-1)) >= 0.5
    #   ORDER BY match_strength DESC
    #   LIMIT 13
    # SQL




    # ordered_phonemes = "SELECT * FROM word_phonemes ORDER BY word_id ASC, r_position ASC"
    # results = WordPhoneme.find_by_sql(<<-SQL)
    #   SELECT sub2.word_id, sum(2 ^ (-sub2.r_vc_block-1)) AS match_strength
    #   FROM (
    #     SELECT word_id, vc_block, r_vc_block, array_agg(phoneme_id) as phonemes, 
    #               array_agg(v_stress) as stresses 
    #     FROM (#{ordered_phonemes}) AS sub WHERE word_id = #{@word.id}
    #     GROUP BY word_id, vc_block, r_vc_block
    #     ORDER BY r_vc_block ASC
    #    ) AS sub1, (
    #      SELECT word_id, vc_block, r_vc_block, array_agg(phoneme_id) as phonemes, 
    #               array_agg(v_stress) as stresses 
    #      FROM (#{ordered_phonemes}) AS sub WHERE word_id != #{@word.id}
    #      GROUP BY word_id, vc_block, r_vc_block
    #      ORDER BY r_vc_block ASC
    #    ) AS sub2
    #    WHERE sub1.r_vc_block = sub2.r_vc_block AND sub1.phonemes = sub2.phonemes
    #    GROUP BY sub2.word_id
    #    ORDER BY match_strength DESC, sub2.word_id ASC 
    #    LIMIT #{@number_of_results}
    # SQL
    

    # results = scope.group("word_id, vc_block, r_vc_block").
    #                 having(matches_any).
    #                 select(["word_id", "vc_block", "r_vc_block", match_strength]).
    #                 order("match_strength DESC, word_id ASC").
    #                 limit(@number_of_results)


    # grouped_word_phonemes_sql = "SELECT word_id, vc_block, r_vc_block, array_agg(phoneme_id) as phonemes, array_agg(v_stress) as stresses FROM word_phonemes GROUP BY word_id, vc_block, r_vc_block"
    # matches_any = wphonemes.each_with_index.map { |wp, i| 
    #   "(#{r_position_field} = #{i} AND phonemes = #{wp.phoneme.id})"
    # }.join(" or ")
    # scope.group("word_id, vc_block, r_vc_block").where()




    #
    # matches_any = wphonemes.each_with_index.map { |wp, i| 
    #   "(#{r_position_field} = #{i} AND phoneme_id = #{wp.phoneme.id})"
    # }.join(" or ")
    # match_strength = "sum(2 ^ (-#{r_position_field}-1)) AS match_strength"
    # is_stressed = "case v_stress when 1 then 1 when 2 then 1 else 0 end"
    # is_last_stressed_position = "case #{r_position_field} when #{position_of_last_stress} then 1 else 0 end"
    # stress_match = "sum((#{is_last_stressed_position})*(#{is_stressed})) AS stress_match"
    # # stress_count = "sum((#{is_stressed})*2^(-#{r_position_field}-1)) AS stress_count"
    # perfect = "case ((sum(2 ^ (-#{r_position_field}-1)) >= #{min_perfect_strength}) AND (sum((#{is_last_stressed_position})*(#{is_stressed})) = 1)) when true then 1 else 0 end AS perfect"
    # ind = @word.phoneme_types.index("vowel")
    # if ind == 0
    #   fronts_match = "case #{position_field} = 0 AND v_stress != 3 AND #{r_position_field} = #{wphonemes.length-1} when true then 2 else 0 end"
    #   identity_status = "sum(#{fronts_match})"
    # else
    #   front_match1 = "case #{position_field} = 0 AND v_stress = 3 when true then 1 else 0 end"
    #   front_match2 = "case #{r_position_field} when #{wphonemes.length-1} then 1 else 0 end"
    #   identity_status = "sum((#{front_match1}) + (#{front_match2}))"
    # end
    # #
    # results = scope.select(["word_phonemes.word_id", match_strength, stress_match, perfect]).
    #   where(matches_any).
    #   where("word_phonemes.word_id != ?", @id).
    #   group("word_phonemes.word_id").
    #   having("#{identity_status} = 0").
    #   order("perfect DESC, match_strength DESC, word_id ASC").
    #   limit(@number_of_results)
    # results.each { |e| p e.attributes }
    # results.select { |e|
    #   if (@perfect=="1")
    #     (e.attributes["match_strength"].to_f >= min_perfect_strength) && (e.attributes["perfect"].to_f == 1)
    #   else
    #     (e.attributes["match_strength"].to_f >= min_strength)
    #   end
    # }.map { |e| Word.find(e.word_id) }
    results.map { |e| Word.find(e.word_id) }
  end

  def phoneme_filter_options 
    # sql = "SELECT DISTINCT phoneme_ids FROM word_phonemes WHERE vc_block = 0"
    # phonemes = Phoneme.all.group_by { |ph| ph.id }
    # opts = [""] + WordPhoneme.find_by_sql(sql).map { |e| 
    #   e.phoneme_ids.map { |id| phonemes[id].first.name }.join("-")
    # }.sort
    opts = [""]
		opts.zip(opts)
  end

  def num_syllables_filter_options
  	labels = ["","1","2","3","4","5","6","7+"]
		vals = ["",1,2,3,4,5,6,7]
		labels.zip(vals)
  end

  def word_type_filter_options
  	opts = ["","noun","adj","adv","verb"]
		opts.zip(opts)
  end

  private

  def filter_by_first_phoneme scope
    if @first_phoneme.present?
      ph_ids = @first_phoneme.split("-").map { |name| Phoneme.where(:name => name).first.id }
      filtered_words = <<-SQL
        INNER JOIN (SELECT word_id AS filtered_word_id FROM word_phonemes
          WHERE vc_block = 0 AND phoneme_ids = ARRAY[#{ph_ids.join(",")}])
        AS fw1 ON fw1.filtered_word_id = word_phonemes.word_id
      SQL
      scope.joins(filtered_words)
    else
      scope
    end
  end

  def filter_by_num_syllables scope
    if @num_syllables.present?
      filtered_words = <<-SQL
        INNER JOIN (SELECT word_id AS filtered_word_id 
          FROM word_phonemes WHERE v_stress < 3 GROUP BY filtered_word_id 
          HAVING count(1) = #{@num_syllables})
        AS fw2 ON fw2.filtered_word_id = word_phonemes.word_id
      SQL
      scope.joins(filtered_words)
    else
      scope
    end
  end

end
