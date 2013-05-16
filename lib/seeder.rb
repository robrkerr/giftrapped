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
    populate_word_phonemes tidy_word_phonemes(word_entries, words.map { |w| w[:phonemes]}, get_phoneme_ids)
  end

  def clear_lexemes
    Lexeme.delete_all
  end

  def seed_lexemes lexemes
    populate_lexemes lexemes
  end

  private

  def get_phoneme_ids
    Phoneme.all.group_by { |p| [p.name,p.stress] }
  end
    
  def tidy_word_phonemes words, word_phonemes, phoneme_ids
    word_phonemes.each_with_index.map { |wps,i| 
      wps.reverse.each_with_index.map { |wp,j| 
        {:word_id => words[i].id, :phoneme_id => phoneme_ids[wp].first.id, :order => j}
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
    Lexeme.transaction do
      Lexeme.import lexemes.map { |lex| Lexeme.new(lex) }
    end
  end
end
