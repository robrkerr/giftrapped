class AddFieldsToWordPhonemes < ActiveRecord::Migration
	def change
		add_column :word_phonemes, :r_order, :integer
		add_column :word_phonemes, :vc_block, :integer
		add_column :word_phonemes, :r_vc_block, :integer
		add_column :word_phonemes, :v_stress, :integer
	end
end
