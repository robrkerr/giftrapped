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
    Pronunciation.delete_all
    WordPronunciation.delete_all
    PronunciationSyllable.delete_all
    SyllableSegment.delete_all
    SegmentPhoneme.delete_all
  end

  def seed_words words, source
    word_names = words.map { |w| w[:name]}
    word_hash = populate_words word_names
    pronunciation_labels = words.map { |w| get_pronunciation_label(w[:syllables]) }
    pron_hash, new_pron_hash = populate_pronunciations pronunciation_labels
    populate_word_pronunciations word_names, pronunciation_labels, word_hash, pron_hash, source
    different_segments = get_all_syllable_segments(words.map { |w| w[:syllables]}.flatten)
    seg_hash = populate_syllable_segments different_segments
    pronunciation_syllables = words.map { |w| w[:syllables] }
    populate_pronunciation_syllables pronunciation_syllables, new_pron_hash, seg_hash
  end

  def clear_lexemes
    Lexeme.delete_all
    WordLexeme.delete_all
  end

  def seed_lexemes word_lexemes, source
    lexemes = []
    word_lexemes.each { |wlex| wlex[:lexemes].each { |lex| 
        lexemes << [wlex[:word],lex[:word_class],lex[:gloss]]
    } }
    lex_hash = populate_lexemes lexemes
    populate_word_lexemes lexemes, lex_hash, source
  end

  def seed_extra_word_lexemes word_relations, source
    add_extra_word_lexemes word_relations, source
  end  

  private

  def get_phoneme_id_hash
    hash = Phoneme.all.group_by { |ph| ph.name }
    hash.each_key { |name| hash[name] = hash[name].first.id }
    hash
  end

  def get_pronunciation_label syllables
    syllables.map { |s| get_syllable_label(s) }.join("-")
  end

  def get_syllable_label s
    [s[:onset], s[:nucleus].first + s[:stress].to_s, s[:coda]].flatten.join("-")
  end

  def get_segment_label segment
    segment.join("-")
  end

  def partition_new_and_existing table, key_fields, key_values, entries
    new_entries = []; existing = {}
    key_values.zip(entries).each { |values, entry| 
      results = table.where(Hash[[*key_fields].zip([*values])])
      if results.count == 0
        new_entries << entry
      else
        existing[values] = results.first
      end
    }
    return new_entries, existing
  end

  def get_all_syllable_segments syllables
    segments = []
    syllables.each { |s| 
      segments << [0,get_segment_label(s[:onset])]
      segments << [1,get_segment_label(s[:nucleus])]
      segments << [2,get_segment_label(s[:coda])]
    }
    segments.uniq
  end

  def populate_words words
    columns = [:name]
    values, word_hash = partition_new_and_existing Word, columns[0], words, words.map { |w| [w] }
    Word.transaction do
      Word.import columns, values, :validate => false
    end
    _, new_word_hash = partition_new_and_existing Word, columns[0], values.map { |v| v[0]}, values
    word_hash.merge(new_word_hash)
  end

  def populate_pronunciations labels
    columns = [:label]
    values, pron_hash = partition_new_and_existing Pronunciation, columns[0], labels, labels.map { |e| [e] }
    Pronunciation.transaction do
      Pronunciation.import columns, values, :validate => false
    end
    _, new_pron_hash = partition_new_and_existing Pronunciation, columns[0], values.map { |v| v[0]}, values
    return pron_hash.merge(new_pron_hash), new_pron_hash
  end

  def populate_word_pronunciations words, labels, word_hash, pron_hash, source
    columns = [:word_id, :pronunciation_id, :source]
    ids = words.zip(labels).map { |w,lab|
      [word_hash[w].id, pron_hash[lab].id]
    }
    values, _ = partition_new_and_existing WordPronunciation, columns[0..1], ids, ids
    WordPronunciation.transaction do
      WordPronunciation.import columns, values.map { |v| v << source; v}, :validate => false
    end
  end

  def populate_syllable_segments different_segments
    columns = [:segment_type,:label]
    values, ss_hash = partition_new_and_existing SyllableSegment, columns[0..1], different_segments, different_segments
    SyllableSegment.transaction do
      SyllableSegment.import columns, values, :validate => false
    end
    _, new_ss_hash = partition_new_and_existing SyllableSegment, columns[0..1], values.map { |v| v[0..1]}, values
    ss_hash = ss_hash.merge(new_ss_hash)
    phid_hash = get_phoneme_id_hash
    columns = [:segment_id,:phoneme_id]
    values = []
    new_ss_hash.each { |(_,label),ss|
      ph_ids = label.split("-").map { |ph| phid_hash[ph] }
      ph_ids.each { |ph_id| values << [ss.id,ph_id] }
    }
    SegmentPhoneme.transaction do
      SegmentPhoneme.import columns, values, :validate => false
    end
    ss_hash
  end

  def populate_pronunciation_syllables pronunciation_syllables, pron_hash, seg_hash
    columns = [:pronunciation_id,:position,:r_position,
                    :onset_id,:nucleus_id,:coda_id,:stress,:label]
    values = []
    pronunciation_syllables.each { |syllables| 
      pron = pron_hash[get_pronunciation_label(syllables)]
      if pron
        syllables.each_with_index { |s,i| 
          r_i = syllables.length-i-1
          onset_id = seg_hash[[0,get_segment_label(s[:onset])]].id
          nucleus_id = seg_hash[[1,get_segment_label(s[:nucleus])]].id
          coda_id = seg_hash[[2,get_segment_label(s[:coda])]].id
          label = get_syllable_label(s)
          values << [pron.id,i,r_i,onset_id,nucleus_id,coda_id,s[:stress],label]
        }
      end
    }
    PronunciationSyllable.transaction do
      PronunciationSyllable.import columns, values, :validate => false
    end
  end

  def populate_lexemes lexemes
    columns = [:word_class,:gloss]
    lexeme_entries = lexemes.map { |lex| lex[1..2]}
    values, lex_hash = partition_new_and_existing Lexeme, columns[0..1], lexeme_entries, lexeme_entries
    Lexeme.transaction do
      Lexeme.import columns, values, :validate => false
    end
    _, new_lex_hash = partition_new_and_existing Lexeme, columns[0..1], values.map { |v| v[0..1]}, values
    lex_hash.merge(new_lex_hash)
  end

  def populate_word_lexemes lexemes, lex_hash, source
    words = lexemes.map { |lex| lex[0]}.uniq
    _, words_hash = partition_new_and_existing Word, :name, words, words
    columns = [:word_id, :lexeme_id, :source]
    ids = lexemes.map { |word,word_class,gloss|
      [words_hash[word].id, lex_hash[[word_class,gloss]].id]
    }
    values, _ = partition_new_and_existing WordLexeme, columns[0..1], ids, ids
    WordLexeme.transaction do
      WordLexeme.import columns, values.map { |v| v << source; v}, :validate => false
    end
  end

  def add_extra_word_lexemes word_relations, source
    words = word_relations.flatten(2)
    _, words_hash = partition_new_and_existing Word, :name, words, words
    columns = [:word_id, :lexeme_id, :source]
    values = []
    word_relations.each { |base_word,related_words|
      lex_ids = WordLexeme.where(:word_id => words_hash[base_word].id)
                          .map(&:lexeme_id)
      related_words.each { |related_word|
        lex_ids.each { |lex_id|
          values << [words_hash[related_word].id, lex_id]
        }
      }
    }
    WordLexeme.transaction do
      WordLexeme.import columns, values.map { |v| v << source; v}, :validate => false
    end
  end
end
