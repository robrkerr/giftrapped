class CreateWordPhonemes < ActiveRecord::Migration
  def change
    create_table :word_phonemes do |t|
      t.references :word
      t.references :phoneme
      t.integer :order

      t.timestamps
    end
    add_index :word_phonemes, :word_id
    add_index :word_phonemes, :phoneme_id
  end
end
