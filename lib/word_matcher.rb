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

	def self.find_words syllables_to_match, num_syllables, match_at_least_num=true, end_syllable_to_match=false, reverse=false, num=10
		syllables_to_match.map! { |s| s ? self.convert_segment_labels_to_ids(s) : s }
		syllable_index_offset = reverse ? syllables_to_match.index { |s| s } : syllables_to_match.reverse.index { |s| s }
		number_to_match = syllables_to_match.count { |e| e }
		if !reverse
			sql_string = syllables_to_match.reverse.each_with_index.map { |syllable,i|
				if syllable
					string = "(r_position = #{i+syllable_index_offset}"
					string += " AND position #{match_at_least_num ? ">" : ""}= #{num_syllables-1-i-syllable_index_offset}" if (i+syllable_index_offset) == 0
					string + self.sql_string_for_syllable(syllable) + ")"
				else 
					""
				end
			}.select { |str| str != "" }.join(" OR ")
			if end_syllable_to_match
				end_syllable_to_match = self.convert_segment_labels_to_ids(end_syllable_to_match)
				number_to_match += 1
				sql_string += " OR (position = 0"
				sql_string += self.sql_string_for_syllable(end_syllable_to_match) + ")"
			end
		else
			sql_string = syllables_to_match.each_with_index.map { |syllable,i|
				if syllable
					string = "(position = #{i-syllable_index_offset}"
					string += " AND r_position #{match_at_least_num ? ">" : ""}= #{num_syllables-1-i+syllable_index_offset}" if (i-syllable_index_offset) == 0
					string + self.sql_string_for_syllable(syllable) + ")"
				else 
					""
				end
			}.select { |str| str != "" }.join(" OR ")
			if end_syllable_to_match
				end_syllable_to_match = self.convert_segment_labels_to_ids(end_syllable_to_match)
				number_to_match += 1
				sql_string += " OR (r_position = 0"
				sql_string += self.sql_string_for_syllable(end_syllable_to_match) + ")"
			end
		end
		results = Syllable.where(sql_string)
									 		.select(:pronunciation_id)
				  				 		.group(:pronunciation_id)
				  				 		.having("count(1) = #{number_to_match}")
				  				 		.order("pronunciation_id ASC")
				  				 		.limit(num)
		pron_ids = results.map { |r| r.pronunciation_id }
		pronunciations = Pronunciation.find(pron_ids).group_by(&:id)
		pron_ids.map { |id| pronunciations[id].first }
	end

	def self.sql_string_for_syllable syllable
		string = ""
		string += " AND onset_id #{syllable[0][1] ? "=" : "!="} #{syllable[0][0]}" unless syllable[0][0]=="*"
		if syllable[3]
			if syllable[1][1]
				string += " AND nucleus_id = #{syllable[1][0]}"
				string += " AND stress = #{syllable[3]}"
			else
				string += " AND (nucleus_id != #{syllable[1][0]}"
				string += " OR stress != #{syllable[3]})"
			end
		else
			string += " AND nucleus_id #{syllable[1][1] ? "=" : "!="} #{syllable[1][0]}" unless syllable[1][0]=="*"
		end
		string += " AND coda_id #{syllable[2][1] ? "=" : "!="} #{syllable[2][0]}" unless syllable[2][0]=="*"
		return string
	end

	def self.convert_segment_labels_to_ids syllable
		stress = false
		converted_syllable = syllable.each_with_index.map { |e,i|
			if e[0] == "*"
				e
			elsif (i==1) && (e[0] =~ /\d/)
				segment = Segment.where({label: e[0][0..-2], segment_type: i}).first
				if segment
					stress = e[0][-1].to_i
					[segment.id,e[1]]
				else
					["*",e[1]]
				end
			else
				segment = Segment.where({label: e[0], segment_type: i}).first
				segment ? [segment.id,e[1]] : ["*",e[1]]
			end
		}
		return converted_syllable + [stress]
	end
end
