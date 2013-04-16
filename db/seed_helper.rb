require "#{Rails.root}/data/load_words.rb"

def seed_timer task_msg, output=true
  print task_msg if output
  time = Time.now if output
  yield
  print "Done. (#{Time.now-time}s)\n" if output
end

def seed_words filename, output=true
  words = []; word_phonemes = []; phonemes = {}
  seed_timer("Reading word file... ", output) {
    words, word_phonemes = load_words(filename)
  }

  seed_timer("Clearing word table... ", output) {
    Word.delete_all
  }
  seed_timer("Tidying word data... ", output) {
    words.map! { |w| {:name => w}}
  }
  seed_timer("Populating word table... ", output) {
    Word.transaction do
      Word.import words.map { |w| Word.new(w) }
      words = Word.order('id ASC').all
    end
  }

  seed_timer("Clearing word-phoneme table... ", output) {
    WordPhoneme.delete_all
  }
  seed_timer("Getting phoneme ids... ", output) {
    phonemes = Phoneme.all.group_by { |p| [p.name,p.stress] }
  }
  seed_timer("Tidying word-phoneme data... ", output) {
    word_phonemes = word_phonemes.each_with_index.map { |wps,i| 
      wps.reverse.each_with_index.map { |wp,j| 
        {:word_id => words[i].id, :phoneme_id => phonemes[wp].first.id, 
              :order => j}
      }
    }
  }
  seed_timer("Populating word-phoneme table... ", output) {
    WordPhoneme.transaction do
      WordPhoneme.import word_phonemes.flatten.map { |wp| WordPhoneme.new(wp) }
    end
  }
end