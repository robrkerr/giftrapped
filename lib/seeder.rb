class Seeder
  def initialize output=true
    @output = output
  end

  def clear_phonemes
    Phoneme.delete_all
  end

  def seed_phonemes phonemes
    Phoneme.create!(phonemes)
  end

  def clear_words
    Word.delete_all
    WordPhoneme.delete_all
  end

  def seed_words words
    words.sort_by! { |w| w[:name] }
    word_entries = populate_words words.map { |w| w.slice(:name)}
    populate_word_phonemes tidy_word_phonemes(word_entries, words.map { |w| w[:phonemes]}, get_phonemes)
  end

  def clear_lexemes
    Lexeme.delete_all
    WordLexeme.delete_all
  end

  def seed_lexemes lexemes, word_lexemes
    first_id = populate_lexemes lexemes
    populate_word_lexemes word_lexemes, first_id
  end

  def seed_extra_word_lexemes word_relations
    add_extra_word_lexemes word_relations
  end

  private

  def get_phonemes
    Phoneme.all.group_by { |p| p.name }
  end
    
  def tidy_word_phonemes words, word_phonemes, phonemes
    word_phonemes.each_with_index.map { |wps,i|
      k = 0
      wps.each_with_index.map { |wp,j| 
        ph = phonemes[wp[0]].first
        k += 1 unless (j==0) || ((ph.ptype=="vowel")==(phonemes[wps[j-1][0]].first.ptype=="vowel"))
        {:word_id => words[i].id, 
         :phoneme_id => ph.id, 
         :position => j,
         :r_position => wps.length-1-j,
         :vc_block => k,
         :v_stress => (ph.ptype=="vowel") ? wp[1] : 3}
      }
    }
  end

  def populate_words words
    all_words_before = Word.all
    Word.transaction do
      Word.import words.map { |w| Word.new(w) }
    end
    (Word.all - all_words_before).sort_by(&:name)
  end

  def populate_word_phonemes word_phonemes
    WordPhoneme.transaction do
      WordPhoneme.import word_phonemes.flatten.map { |wp| WordPhoneme.new(wp) }
    end
  end

  def populate_lexemes lexemes
    last_lexeme = Lexeme.all.sort_by(&:lexeme_id).last
    first_id = last_lexeme ? last_lexeme.id+1 : 0
    Lexeme.transaction do
      Lexeme.import lexemes.map { |lex| lex[:lexeme_id] += first_id; Lexeme.new(lex) }
    end
    first_id
  end

  def populate_word_lexemes word_lexemes, first_id
    word_lexeme_entries = []
    word_lexemes.each { |k,v|
      Word.where("name = '#{k}'").each { |word|
        v.each { |lexeme_id|
          word_lexeme_entries << {:word_id => word.id, :lexeme_id => lexeme_id + first_id }
        }
      }
    }
    WordLexeme.transaction do
      WordLexeme.import word_lexeme_entries.map { |wl| WordLexeme.new(wl) }
    end
  end

  def add_extra_word_lexemes word_relations
    word_lexeme_entries = []
    word_relations.each { |word_name,related_words|
      Word.where("name = '#{word_name}'").each { |word|
        lex_ids = word.word_lexemes.map(&:lexeme_id)
        related_words.each { |related_word_name|
          Word.where("name = '#{related_word_name}'").each { |related_word|
            lex_ids.each { |lex_id|
              word_lexeme_entries << {:word_id => related_word.id, 
                                      :lexeme_id => lex_id }
            }
          }
        }
      }
    }
    WordLexeme.transaction do
      WordLexeme.import word_lexeme_entries.map { |wl| WordLexeme.new(wl) }
    end
  end
end
