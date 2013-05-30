class CreateWordLexemes < ActiveRecord::Migration
  def change
    create_table :word_lexemes do |t|
      t.references :word
      t.references :lexeme

      t.timestamps
    end
    add_index :word_lexemes, :word_id
    add_index :word_lexemes, :lexeme_id
  end
end
