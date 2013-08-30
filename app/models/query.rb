require 'word_matcher'

class Query
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

  attr_accessor :word, :id, :text, :first_segment, :num_syllables
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
    @first_segment = params[:first_segment] || ""
    @num_syllables = params[:num_syllables] || ""
    @word_type = params[:word_type] || ""
    @reverse = params[:reverse] || "0"
    @perfect = params[:perfect] || "0"
    @dictionary = params[:dictionary] || "0"
    @auto_complete = params[:autocomplete] || "words"
    @term = params[:term] || false
    @number_of_results = 13
    if params[:id].present?
      @id = params[:id].to_i
      @word = Word.find(@id)
      @text = @word.name
    else
      @text = params[:text].present? ? parse_text(params[:text]) : ""
      @word = Spelling.where(:label => @text).try(&:first).try(&:words).try(&:first) || nil
      @id = @word.id if @word
    end
  end

  def parse_text text
    # text.downcase.split(" ").last.split("-").last
    text.downcase.split(" ").last
  end

  def persisted?
    false
  end

  def auto_complete number
    if @auto_complete == "words"
      auto_complete_words number
    elsif @auto_complete == "segments"
      auto_complete_segments number
    else
      []
    end
  end

  def auto_complete_words number
    return [] unless @term
    words = Spelling.where("label LIKE ?", "#{@term}%").limit(number).map { |sp| sp.words }.flatten
    words.map { |w| {
        :label => w.name, 
        :phonetic_label => w.pronunciation.label,
        :num_syllables => w.num_syllables,
        :id => w.id
      }
    }
  end

  def auto_complete_segments number
    return [] unless @term
    if reversed_mode
      segments = Segment.select([:id,:label,:segment_type])
                     .where(["label LIKE ? AND segment_type > ?", "#{@term}%", 0])
                     .order(:label)
                     .limit(number)
      segments.map { |segment| {
          :label => segment.label, 
          :id => segment.id,
          :type => segment.segment_type
        }
      }
    else
      segments = Segment.select([:id,:label,:segment_type])
                        .where(["label LIKE ? AND segment_type < ?", "#{@term}%", 2])
                        .order(:label)
                        .limit(number)
      segments.map { |segment| {
          :label => segment.label, 
          :id => segment.id,
          :type => segment.segment_type
        }
      }
    end
  end

  def first_segment_text
    @first_segment.present? ? Segment.find(@first_segment).label : ""
  end

  def first_segment_type
    Segment.find(@first_segment).segment_type
  end

  def dictionary_results text
    spelling = Spelling.where(label: text).first
    words = spelling.words
    linked_results = Word.select("words.id, lexemes.word_class, lexemes.gloss")
                         .where(:id => words.map(&:id))
                         .joins("LEFT JOIN word_lexemes ON word_lexemes.word_id = words.id
                                 LEFT JOIN lexemes ON lexemes.id = word_lexemes.lexeme_id")
                         .map(&:attributes)
                         .group_by { |r| r["id"] }
    word_id_to_syllables = Syllable.where(:pronunciation_id => words.map(&:pronunciation_id))
                                   .order("position ASC").group_by(&:pronunciation_id)
    words.each_with_index.map { |word,i| 
      syllables = word_id_to_syllables[word.pronunciation_id]
      p linked_results
      lexemes = linked_results[word.id].each_with_index.map { |word_lexeme,j|
        if word_lexeme["word_class"] && word_lexeme["gloss"]
          "#{j+1}: (" + word_lexeme["word_class"] + ") " + word_lexeme["gloss"] + "."
        else 
          nil
        end
      }.compact
      word_hash = { name: spelling.label, num_syllables: syllables.length, 
                        lexemes: lexemes, word_id: word.id }
      { primary_word: word_hash, 
        other_words: [], 
        even_tag: (i%2==0) ? "even" : "odd",
        pronunciation_label: syllables.map(&:label).join("-"), 
        syllables: reversed_mode ? syllables : syllables.reverse }
    }
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
      hash[:first_segment] = @first_segment if @first_segment.present?
      hash[:num_syllables] = @num_syllables if @num_syllables.present?
      hash[:word_type] = @word_type if @word_type.present?
      hash[:reverse] = @reverse if @reverse.present? && @reverse == "1"
      hash[:perfect] = @perfect if @perfect.present? && @perfect == "1"
    end
    hash
  end

  def rhyming_link word_id
    optional_params.merge({:id => word_id})
  end

  def words_to_show
    if @words_to_show_cached 
      # return that
    elsif !valid?
      @words_to_show_cached = []
    elsif dictionary_mode
      @words_to_show_cached = dictionary_results @word.name
    else
      @words_to_show_cached = run_query
    end
    @words_to_show_cached
  end

  def dictionary_mode
    @dictionary=="1"
  end

  def reversed_mode
    @reverse=="1"
  end

  def reversed_tag
    reversed_mode ? "reversed" : "normal_order"
  end

  def run_query
    scope = filter_by_first_segment filter_by_num_syllables(Syllable)
    pronunciations = WordMatcher.find_rhymes @word.pronunciation, scope, @number_of_results, reversed_mode
    pron_ids = pronunciations.map { |pron| pron.id }
    linked_results = Word.select("pronunciation_id, words.id, spellings.label, lexemes.word_class, lexemes.gloss")
                         .where(:pronunciation_id => pron_ids)
                         .joins("LEFT JOIN spellings ON spellings.id = words.spelling_id
                                 LEFT JOIN word_lexemes ON word_lexemes.word_id = words.id
                                 LEFT JOIN lexemes ON lexemes.id = word_lexemes.lexeme_id")
                         .map(&:attributes)
                         .group_by { |r| r["pronunciation_id"] }
    pron_id_to_syllables = Syllable.where(:pronunciation_id => pron_ids).order("position ASC").group_by(&:pronunciation_id)
    pron_ids.map { |id| linked_results[id] }.each_with_index.map { |pron_words,i| 
      syllables = pron_id_to_syllables[pronunciations[i].id]
      words = pron_words.group_by { |w| w["id"] }
      words_sorted = words.keys.map { |id| 
        lexemes = words[id].each_with_index.map { |word_lexeme,j|
          if word_lexeme["word_class"] && word_lexeme["gloss"]
            "#{j+1}: (" + word_lexeme["word_class"] + ") " + word_lexeme["gloss"] + "."
          else 
            nil
          end
        }.compact
        { name: words[id].first["label"], num_syllables: syllables.length, 
                        lexemes: lexemes, word_id: id}
      }.sort_by { |word| -word[:lexemes].length }
      { primary_word: words_sorted.first, 
        other_words: words_sorted[1..-1], 
        even_tag: (i%2==0) ? "even" : "odd",
        pronunciation_label: pronunciations[i].label, 
        syllables: reversed_mode ? syllables : syllables.reverse }
    }
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

  def filter_by_first_segment scope
    if @first_segment.present?
      case first_segment_type
      when 0
        segment_condition = "onset_id = #{@first_segment}"
      when 1
        if reversed_mode
          blank_id = Segment.select(:id).where({label: "", segment_type: 2}).first.id
          segment_condition = "nucleus_id = #{@first_segment} AND coda_id = #{blank_id}"
        else
          blank_id = Segment.select(:id).where({label: "", segment_type: 0}).first.id
          segment_condition = "nucleus_id = #{@first_segment} AND onset_id = #{blank_id}"
        end
      when 2
        segment_condition = "coda_id = #{@first_segment}"
      end
      if reversed_mode
        position_condition = "r_position = 0"
      else
        position_condition = "position = 0"
      end
      filtered_pronunciations = <<-SQL
        INNER JOIN (SELECT pronunciation_id AS filtered_pronunciation_id 
          FROM syllables 
          WHERE #{position_condition} 
          AND #{segment_condition})
        AS fw1 ON fw1.filtered_pronunciation_id = syllables.pronunciation_id
      SQL
      scope.joins(filtered_pronunciations)
    else
      scope
    end
  end

  def filter_by_num_syllables scope
    if @num_syllables.present?
      filtered_pronunciations = <<-SQL
        INNER JOIN (SELECT pronunciation_id AS filtered_pronunciation_id
          FROM syllables GROUP BY pronunciation_id 
          HAVING count(1) = #{@num_syllables})
        AS fw2 ON fw2.filtered_pronunciation_id = syllables.pronunciation_id
      SQL
      scope.joins(filtered_pronunciations)
    else
      scope
    end
  end

end
