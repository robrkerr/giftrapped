require "#{Rails.root}/data/load_words.rb"

def seed_timer task_msg, output=true
  print task_msg if output
  time = Time.now if output
  yield
  print "Done. (#{Time.now-time}s)\n" if output
end

def seed_words filename, output=true
  words = []; word_phonemes = []; phonemes = {}
  seed_timer("  Reading word file... ", output) {
    words, word_phonemes = load_words(filename)
    wwp = words.zip(word_phonemes).sort_by { |w,wp| w }
    words = wwp.map { |w,wp| w }
    word_phonemes = wwp.map { |w,wp| wp }
  }

  seed_timer("  Tidying word data... ", output) {
    words.map! { |w| {:name => w}}
  }
  seed_timer("  Populating word table... ", output) {
    all_words_before = Word.all
    Word.transaction do
      Word.import words.map { |w| Word.new(w) }
    end
    words = (Word.all - all_words_before).sort_by(&:name)
  }

  seed_timer("  Getting phoneme ids... ", output) {
    phonemes = Phoneme.all.group_by { |p| [p.name,p.stress] }
  }
  seed_timer("  Tidying word-phoneme data... ", output) {
    word_phonemes = word_phonemes.each_with_index.map { |wps,i| 
      wps.reverse.each_with_index.map { |wp,j| 
        {:word_id => words[i].id, :phoneme_id => phonemes[wp].first.id, 
              :order => j}
      }
    }
  }
  seed_timer("  Populating word-phoneme table... ", output) {
    WordPhoneme.transaction do
      WordPhoneme.import word_phonemes.flatten.map { |wp| WordPhoneme.new(wp) }
    end
  }
end