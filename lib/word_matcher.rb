class WordMatcher

	# def self.find_rhymes pronunciation, scope=Syllable, num=10, reverse=false
	# 	if reverse
	# 		syllables = pronunciation.syllables
	# 	else
	# 		syllables = pronunciation.syllables.reverse
	# 	end
	# 	matches_any_nucleus_and_coda = syllables.each_with_index.map { |syllable, i| 
 #    	if reverse
 #    		"(position = #{i} AND nucleus_id = #{syllable[:nucleus_id]} AND onset_id = #{syllable[:onset_id]})"
 #    	else
 #    		"(r_position = #{i} AND nucleus_id = #{syllable[:nucleus_id]} AND coda_id = #{syllable[:coda_id]})"
 #    	end
 #  	}.join(" OR ")
 #  	matches_any_onset = syllables.each_with_index.map { |syllable, i|
 #  		if reverse
 #  			"(position = #{i} AND coda_id = #{syllable[:coda_id]})"
 #  		else
 #    		"(r_position = #{i} AND onset_id = #{syllable[:onset_id]})"
 #    	end
 #  	}.join(" OR ")
 #  	matches_onset = "CASE WHEN (#{matches_any_onset}) THEN 2 ELSE 1 END"  	
 #  	if reverse
 #  		match_strength = "ceil(-log(3.0,(1-sum((#{matches_onset})*(3^(-position-1))))::numeric)) AS match_strength"
 #  		match_type = "mod(0.0000001-log(3.0,(1-sum((#{matches_onset})*(3^(-position-1))))::numeric),1.0) > -log(3.0,0.666667)"
 #  	else
 #  		match_strength = "ceil(-log(3.0,(1-sum((#{matches_onset})*(3^(-r_position-1))))::numeric)) AS match_strength"
 #  		match_type = "mod(0.0000001-log(3.0,(1-sum((#{matches_onset})*(3^(-r_position-1))))::numeric),1.0) > -log(3.0,0.666667)"
 #  	end
 #  	results = scope.where(matches_any_nucleus_and_coda)
	# 								 .select([:pronunciation_id, match_strength])
	# 			  				 .group(:pronunciation_id)
	# 			  				 .having(match_type)
	# 			  				 .order("match_strength DESC")
	# 			  				 .limit(num)
	# 	results.map { |r|
	# 		Pronunciation.find(r.pronunciation_id)
	# 	}
	# end

	def self.find_rhymes pronunciation, scope=Syllable, num=10, reverse=false
		syllables = [*pronunciation].map { |word| 
			reverse ? word.syllables : word.syllables.reverse
		}.flatten
		number_to_match = syllables.length
		results = []
		while results.length < num
			break if number_to_match == 0
			if syllables[number_to_match-1].stress == 0
				number_to_match -= 1
				next
			end
			rhymes = syllables[0..(number_to_match-1)].each_with_index.map { |syllable, i|
				if reverse
					string_beginning = "(position = #{i} AND onset_id = #{syllable[:onset_id]}"
				else
					string_beginning = "(r_position = #{i} AND coda_id = #{syllable[:coda_id]}"
				end
				string = string_beginning + " AND nucleus_id = #{syllable[:nucleus_id]}"
				if i == (number_to_match-1)
					if reverse
		    			string + " AND coda_id != #{syllable[:coda_id]} AND stress > 0)"
					else
						string + " AND onset_id != #{syllable[:onset_id]} AND stress > 0)"
					end
				elsif syllable.stress > 0
					if reverse
		    		string + " AND (r_position > 0 OR coda_id != #{syllable[:coda_id]}) AND stress > 0)"
					else
						string + " AND (position > 0 OR onset_id != #{syllable[:onset_id]}) AND stress > 0)"
					end
		    else
		    	if reverse
		    		string + " AND coda_id = #{syllable[:coda_id]})"
					else
						string + " AND onset_id = #{syllable[:onset_id]})"
					end
		    end
  		}.join(" OR ")
  		new_results = scope.where(rhymes)
												 .select(:pronunciation_id)
							  				 .group(:pronunciation_id)
							  				 .having("count(1) = #{number_to_match}")
							  				 .order("pronunciation_id ASC")
							  				 # .limit(num - results.length)
			results.concat(new_results.take(num - results.length))
			number_to_match -= 1
		end
		pron_ids = results.map { |r| r.pronunciation_id }
		pronunciations = Pronunciation.find(pron_ids).group_by(&:id)
		pron_ids.map { |id| pronunciations[id].first }
	end

	# def self.find_portmanteaus pronunciation, scope=Syllable, num=10, reverse=false
	# 	if reverse
	# 		syllable = pronunciation.syllables.first
	# 		position_condition = "r_position = 0"
	# 	else
	# 		syllable = pronunciation.syllables.last
	# 		position_condition = "position = 0"
	# 	end
	# 	condition = position_condition + " AND nucleus_id = #{syllable[:nucleus_id]}" + 
	# 												" AND onset_id = #{syllable[:onset_id]}" + 
	# 												" AND coda_id = #{syllable[:coda_id]}"
 #  	results = scope.where(condition)
	# 								 .select(:pronunciation_id)
	# 			  				 .limit(num)
	# 	results.map { |r|
	# 		Pronunciation.find(r.pronunciation_id)
	# 	}
	# end

end