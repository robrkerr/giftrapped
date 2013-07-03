class WordMatcher

	def self.find_rhymes pronunciation, scope=Syllable, num=10
		syllables = pronunciation.syllables.reverse
		matches_any_nucleus_and_coda = syllables.each_with_index.map { |syllable, i| 
    	"(r_position = #{i} AND nucleus_id = #{syllable[:nucleus_id]} AND coda_id = #{syllable[:coda_id]})"
  	}.join(" OR ")
  	matches_any_onset = syllables.each_with_index.map { |syllable, i| 
    	"(r_position = #{i} AND onset_id = #{syllable[:onset_id]})"
  	}.join(" OR ")
  	matches_onset = "CASE WHEN (#{matches_any_onset}) THEN 2 ELSE 1 END"
  	match_type = "mod(-log(3.0,(1-sum((#{matches_onset})*(3^(-r_position-1))))::numeric),1.0) >= -log(3.0,0.66666667)"
  	match_strength = "ceil(-log(3.0,(1-sum((#{matches_onset})*(3^(-r_position-1))))::numeric)) AS match_strength"
  	results = scope.where(matches_any_nucleus_and_coda)
  										.select([:pronunciation_id, match_strength])
					  					.group(:pronunciation_id)
					  					.having(match_type)
					  					.order("match_strength DESC")
					  					.limit(num)
		# results.map { |r| 
		# 	p [Pronunciation.find(r.pronunciation_id).syllables.map(&:label),r.attributes["match_strength"]]
		# }
		Pronunciation.find(results.map(&:pronunciation_id))
	end

end