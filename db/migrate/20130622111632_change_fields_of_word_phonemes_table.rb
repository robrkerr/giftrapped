class ChangeFieldsOfWordPhonemesTable < ActiveRecord::Migration
  def up
	add_column :word_phonemes, :phoneme_ids, :integer_array
	remove_column :word_phonemes, :position
	remove_column :word_phonemes, :r_position
	remove_column :word_phonemes, :phoneme_id

    add_index :word_phonemes, [:r_vc_block, :phoneme_ids]
    add_index :word_phonemes, [:vc_block, :phoneme_ids]
  end

  def down
  	remove_column :word_phonemes, :phoneme_ids
	add_column :word_phonemes, :position, :integer
	add_column :word_phonemes, :r_position, :integer
	add_column :word_phonemes, :phoneme_id, :integer

	add_index :word_phonemes, :phoneme_id
  end
end
